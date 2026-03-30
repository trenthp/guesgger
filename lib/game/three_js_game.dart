import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../config/game_config.dart';
import 'components/npc_state.dart';
import 'components/obstacle_state.dart';
import 'components/player_state.dart';
import 'components/scenery_state.dart';
import 'obstacles/obstacle_data.dart';
import 'three_js/model_manager.dart';
import 'three_js/scene_sync.dart';
import 'three_js/three_bridge.dart';
import 'world_state.dart';
import 'zones/zone_manager.dart';

/// Main game controller — replaces the Flame [FroggerGame].
///
/// Runs a game loop via Flutter's [Ticker], owns all game state,
/// and delegates rendering to [SceneSync] → [ThreeBridge] → three.js.
class ThreeJsGame {
  late WorldState worldState;
  late ZoneManager zoneManager;
  late PlayerState player;
  late NpcManager npcManager;
  late SceneryManager sceneryManager;
  late ModelManager modelManager;
  SceneSync? _sceneSync;

  final List<ObstacleState> _obstacles = [];
  int _nextObstacleId = 0;

  // Obstacle spawning
  final Random _random = Random();
  double _spawnTimer = 2.0;
  double _timeSinceLastGate = 0;

  // Callbacks for UI
  VoidCallback? onGameOver;
  VoidCallback? onWin;
  VoidCallback? onStateChanged;

  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  bool _initialized = false;
  bool get isInitialized => _initialized;

  double _screenWidth = 0;
  double _screenHeight = 0;

  /// Initialize game state and preload models.
  Future<void> initialize(TickerProvider vsync) async {
    worldState = WorldState();
    zoneManager = ZoneManager();
    player = PlayerState();
    npcManager = NpcManager(
      getDistanceTraveled: () => worldState.distanceTraveled,
      getCurrentSpeed: () => worldState.currentSpeed,
      getSpeedMultiplier: () => worldState.zoneSpeedMultiplier,
      getCurrentZone: () => zoneManager.currentZone,
      getZoneAtDistance: (d) => zoneManager.getZoneAtDistance(d),
    );
    sceneryManager = SceneryManager(
      getDistanceTraveled: () => worldState.distanceTraveled,
      getCurrentSpeed: () => worldState.currentSpeed,
      getSpeedMultiplier: () => worldState.zoneSpeedMultiplier,
      getCurrentZone: () => zoneManager.currentZone,
      getZoneAtDistance: (d) => zoneManager.getZoneAtDistance(d),
    );
    modelManager = ModelManager();

    // Preload models (non-blocking — fallback boxes render if not ready)
    modelManager.preloadAll();

    _initialized = true;
    onStateChanged?.call();
  }

  /// Start the game loop. Call after the three.js canvas is ready.
  void start(double screenWidth, double screenHeight) {
    _screenWidth = screenWidth;
    _screenHeight = screenHeight;

    _sceneSync = SceneSync(
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );
  }

  /// Attach the ticker to start the game loop.
  void attachTicker(TickerProvider vsync) {
    _ticker?.dispose();
    _ticker = vsync.createTicker(_onTick);
    _lastTick = Duration.zero;
    _ticker!.start();
  }

  void _onTick(Duration elapsed) {
    if (!_initialized || _sceneSync == null) return;

    final dt =
        _lastTick == Duration.zero ? 0.016 : (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;

    // Clamp dt to avoid huge jumps on tab-away
    final clampedDt = dt.clamp(0.0, 0.05);

    _update(clampedDt);
  }

  void _update(double dt) {
    if (worldState.status != GameStatus.playing) return;

    // Update zone
    zoneManager.update(worldState.distanceTraveled);
    final zone = zoneManager.currentZone;
    worldState.zoneSpeedMultiplier = zone.speedMultiplier;
    worldState.onReverseWalkway = zone.reversesDirection;

    // Update world state
    worldState.update(dt);
    player.isInvulnerable = worldState.isInvulnerable;
    player.isStunned = worldState.isStunned;

    // Check game end states
    if (worldState.status == GameStatus.won) {
      onWin?.call();
      return;
    }
    if (worldState.status == GameStatus.gameOver) {
      onGameOver?.call();
      return;
    }

    // Player update
    player.update(dt);

    // While stunned, freeze obstacles but let NPCs walk
    final removedNpcIds = npcManager.update(dt);
    final removedSceneryIds = sceneryManager.update(dt);

    if (!worldState.isStunned) {
      // Spawn obstacles
      _updateSpawner(dt);

      // Move obstacles
      final moveDistance =
          worldState.currentSpeed * worldState.zoneSpeedMultiplier * dt;
      final removedObstacleIds = <String>[];

      _obstacles.removeWhere((obs) {
        obs.advance(moveDistance);
        if (obs.isPastCamera) {
          removedObstacleIds.add(obs.sceneId);
          return true;
        }
        _checkObstacleCollision(obs);
        return false;
      });

      if (removedObstacleIds.isNotEmpty) {
        _sceneSync!.removeObstacles(removedObstacleIds);
      }

      // NPC collisions
      _checkNpcCollisions();
    }

    // Sync scene
    _sceneSync!.sync(
      player: player,
      obstacles: _obstacles,
      npcManager: npcManager,
      sceneryManager: sceneryManager,
      worldState: worldState,
      zoneManager: zoneManager,
      removedNpcIds: removedNpcIds,
      removedSceneryIds: removedSceneryIds,
      dt: dt,
    );

    onStateChanged?.call();
  }

  // --- Obstacle spawning (extracted from ObstacleSpawner) ---

  void _updateSpawner(double dt) {
    final zone = zoneManager.currentZone;
    if (zone.obstaclePool.isEmpty) return;

    _timeSinceLastGate += dt;
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawn();
      _spawnTimer = zone.spawnIntervalMin +
          _random.nextDouble() * (zone.spawnIntervalMax - zone.spawnIntervalMin);
    }
  }

  void _spawn() {
    final zone = zoneManager.currentZone;
    if (zone.obstaclePool.isEmpty) return;

    // Security gate special case
    if (zone.obstaclePool.contains(ObstacleData.metalDetector) &&
        _timeSinceLastGate > 6.0 &&
        _random.nextDouble() < 0.25) {
      _spawnSecurityGate();
      return;
    }

    final data = zone.obstaclePool[_random.nextInt(zone.obstaclePool.length)];

    if (data.spansAllLanes) {
      _addObstacle(data: data, lane: 0, worldZ: GameConfig.spawnDistance);
    } else {
      final pattern = _random.nextDouble();
      if (pattern < 0.5) {
        _spawnSingle(data);
      } else if (pattern < 0.8) {
        _spawnDouble(data);
      } else {
        _spawnStaggered(data);
      }
    }
  }

  void _spawnSecurityGate() {
    final blockedLane = _random.nextInt(3) - 1;
    _addObstacle(
      data: ObstacleData.securityGate,
      lane: 0,
      worldZ: GameConfig.spawnDistance,
      blockedLane: blockedLane,
    );
    _timeSinceLastGate = 0;
  }

  void _spawnSingle(ObstacleData data) {
    final lane = _random.nextInt(3) - 1;
    _addObstacle(data: data, lane: lane, worldZ: GameConfig.spawnDistance);
  }

  void _spawnDouble(ObstacleData data) {
    final lanes = [-1, 0, 1]..shuffle(_random);
    for (int i = 0; i < 2; i++) {
      _addObstacle(data: data, lane: lanes[i], worldZ: GameConfig.spawnDistance);
    }
  }

  void _spawnStaggered(ObstacleData data) {
    final lane1 = _random.nextInt(3) - 1;
    int lane2 = _random.nextInt(3) - 1;
    while (lane2 == lane1) {
      lane2 = _random.nextInt(3) - 1;
    }
    _addObstacle(data: data, lane: lane1, worldZ: GameConfig.spawnDistance);
    _addObstacle(data: data, lane: lane2, worldZ: GameConfig.spawnDistance + 15);
  }

  void _addObstacle({
    required ObstacleData data,
    required int lane,
    required double worldZ,
    int? blockedLane,
  }) {
    _obstacles.add(ObstacleState(
      data: data,
      lane: lane,
      worldZ: worldZ,
      sceneId: 'obs_${_nextObstacleId++}',
      blockedLane: blockedLane,
    ));
  }

  // --- Collision detection (same logic as original FroggerGame) ---

  void _checkObstacleCollision(ObstacleState obstacle) {
    if (worldState.isInvulnerable) return;

    final playerLane = player.currentLane;
    final obstacleLane = obstacle.lane;

    final zDiff = (obstacle.worldZ - GameConfig.playerWorldZ).abs();
    if (zDiff > GameConfig.collisionThreshold) return;

    // Security gate
    if (obstacle.data.blocksJump && obstacle.blockedLane != null) {
      if (playerLane != obstacle.blockedLane) return;
      _triggerHit();
      return;
    }

    final laneMatch = obstacle.data.spansAllLanes || playerLane == obstacleLane;
    if (!laneMatch) return;

    if (obstacle.data.requiresJump && player.isJumping) return;
    if (!obstacle.data.requiresJump && player.isJumping) return;

    _triggerHit();
  }

  void _checkNpcCollisions() {
    if (worldState.isInvulnerable) return;

    for (final npc in npcManager.npcs) {
      if (npc.data.lane != player.currentLane) continue;
      final zDiff = (npc.worldZ - GameConfig.playerWorldZ).abs();
      if (zDiff > GameConfig.collisionThreshold) continue;
      if (player.isJumping) continue;

      _triggerHit();
      return;
    }
  }

  void _triggerHit() {
    worldState.onHit();
    _sceneSync?.triggerHitFlash();
    onStateChanged?.call();

    if (worldState.status == GameStatus.gameOver) {
      onGameOver?.call();
    }
  }

  // --- Input ---

  void moveLeft() {
    if (!_initialized || worldState.status != GameStatus.playing) return;
    if (worldState.isStunned) return;
    player.moveLane(-1);
  }

  void moveRight() {
    if (!_initialized || worldState.status != GameStatus.playing) return;
    if (worldState.isStunned) return;
    player.moveLane(1);
  }

  void jump() {
    if (!_initialized || worldState.status != GameStatus.playing) return;
    if (worldState.isStunned) return;
    player.jump();
  }

  /// Handle keyboard input.
  KeyEventResult onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.keyA) {
        moveLeft();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.keyD) {
        moveRight();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW ||
          event.logicalKey == LogicalKeyboardKey.space) {
        jump();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// Reset for a new game.
  void restart() {
    // Remove all objects from the scene
    final allIds = <String>[
      'player',
      ..._obstacles.map((o) => o.sceneId),
      ...npcManager.npcs.map((n) => n.sceneId),
      ...sceneryManager.items.map((s) => s.sceneId),
    ];
    if (allIds.isNotEmpty && ThreeBridge.instance.isInitialized) {
      ThreeBridge.instance.syncScene({'remove': allIds});
    }

    _obstacles.clear();
    _nextObstacleId = 0;
    _spawnTimer = 2.0;
    _timeSinceLastGate = 0;

    worldState.reset();
    zoneManager.reset();
    npcManager.reset();
    sceneryManager.reset();
    player.reset();
    _sceneSync?.reset();

    _lastTick = Duration.zero;
    onStateChanged?.call();
  }

  void dispose() {
    _ticker?.dispose();
    _ticker = null;
  }
}
