import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/game_config.dart';
import 'components/ground.dart';
import 'components/npc.dart';
import 'components/obstacle.dart';
import 'components/park_entrance.dart';
import 'components/player.dart';
import 'effects/ambient_effects.dart';
import 'effects/hit_effect.dart';
import 'effects/speed_lines.dart';
import 'obstacles/obstacle_spawner.dart';
import 'perspective.dart';
import 'sprites/sprite_manager.dart';
import 'world_state.dart';
import 'zones/zone_manager.dart';

class FroggerGame extends FlameGame with KeyboardEvents {
  PerspectiveProjection perspective = PerspectiveProjection(
    screenWidth: 1,
    screenHeight: 1,
  );
  late WorldState worldState;
  bool _initialized = false;
  bool get isInitialized => _initialized;
  late ZoneManager zoneManager;
  late Player player;
  late Ground ground;
  late ObstacleSpawner obstacleSpawner;
  late SpeedLines speedLines;
  late HitEffect hitEffect;
  late NpcManager npcManager;
  late ParkEntrance parkEntrance;
  late AmbientEffects ambientEffects;
  late SpriteManager spriteManager;

  final List<ObstacleComponent> _obstacles = [];

  // Callbacks for UI overlay
  VoidCallback? onGameOver;
  VoidCallback? onWin;
  VoidCallback? onStateChanged;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    perspective = PerspectiveProjection(
      screenWidth: size.x,
      screenHeight: size.y,
    );

    // Initialize sprite manager (loads available assets, skips missing ones)
    spriteManager = SpriteManager();
    await spriteManager.initialize();

    worldState = WorldState();
    zoneManager = ZoneManager();

    player = Player(perspective: perspective, spriteManager: spriteManager);
    ground = Ground(
      perspective: perspective,
      zoneManager: zoneManager,
      getDistanceTraveled: () => worldState.distanceTraveled,
    );

    hitEffect = HitEffect();
    speedLines = SpeedLines(
      perspective: perspective,
      getSpeed: () => worldState.currentSpeed * worldState.zoneSpeedMultiplier,
    );

    obstacleSpawner = ObstacleSpawner(
      zoneManager: zoneManager,
      perspective: perspective,
      onSpawn: _addObstacle,
      spriteManager: spriteManager,
    );
    obstacleSpawner.reset();

    parkEntrance = ParkEntrance(
      perspective: perspective,
      getDistanceTraveled: () => worldState.distanceTraveled,
    );

    ambientEffects = AmbientEffects(
      perspective: perspective,
      zoneManager: zoneManager,
    );

    npcManager = NpcManager(
      perspective: perspective,
      getDistanceTraveled: () => worldState.distanceTraveled,
      getCurrentSpeed: () => worldState.currentSpeed,
      getSpeedMultiplier: () => worldState.zoneSpeedMultiplier,
      getCurrentZone: () => zoneManager.currentZone,
      getZoneAtDistance: (d) => zoneManager.getZoneAtDistance(d),
      spriteManager: spriteManager,
    );

    // Add components in render order (back to front)
    add(ground);
    add(speedLines);
    add(ambientEffects);
    add(parkEntrance);
    add(npcManager);
    add(player);
    add(hitEffect);

    _initialized = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    perspective.resize(Size(size.x, size.y));
  }

  @override
  void update(double dt) {
    if (!_initialized || worldState.status != GameStatus.playing) {
      super.update(dt);
      return;
    }

    // Clamp dt to avoid big jumps on tab-away
    final double clampedDt = dt.clamp(0, 0.05).toDouble();

    // Update zone
    zoneManager.update(worldState.distanceTraveled);
    final zone = zoneManager.currentZone;
    worldState.zoneSpeedMultiplier = zone.speedMultiplier;
    worldState.onReverseWalkway = zone.reversesDirection;

    // Update world state (distance, score, invulnerability)
    worldState.update(clampedDt);
    player.isInvulnerable = worldState.isInvulnerable;
    player.isStunned = worldState.isStunned;

    // Check for game end states
    if (worldState.status == GameStatus.won) {
      onWin?.call();
      return;
    }
    if (worldState.status == GameStatus.gameOver) {
      onGameOver?.call();
      return;
    }

    // While stunned, freeze world scroll and obstacles but let NPCs keep walking
    if (worldState.isStunned) {
      // NPCs still update (they walk around the fallen player)
      onStateChanged?.call();
      super.update(clampedDt);
      return;
    }

    // Spawn obstacles
    obstacleSpawner.update(clampedDt);

    // Move obstacles toward camera
    final moveDistance =
        worldState.currentSpeed * worldState.zoneSpeedMultiplier * clampedDt;

    final toRemove = <ObstacleComponent>[];
    for (final obstacle in _obstacles) {
      obstacle.advance(moveDistance);
      if (obstacle.isPastCamera) {
        toRemove.add(obstacle);
        continue;
      }

      // Collision check
      _checkCollision(obstacle);
    }

    // Clean up passed obstacles
    for (final obs in toRemove) {
      obs.removeFromParent();
      _obstacles.remove(obs);
    }

    // NPC collision check
    _checkNpcCollisions();

    onStateChanged?.call();
    super.update(clampedDt);
  }

  void _checkCollision(ObstacleComponent obstacle) {
    if (worldState.isInvulnerable) return;

    final playerLane = player.currentLane;
    final obstacleLane = obstacle.lane;

    // Z proximity check
    final zDiff = (obstacle.worldZ - GameConfig.playerWorldZ).abs();
    if (zDiff > GameConfig.collisionThreshold) return;

    // Security gate: one lane is blocked, other two are doorways. Can't jump over.
    if (obstacle.data.blocksJump && obstacle.blockedLane != null) {
      if (playerLane != obstacle.blockedLane) return; // safe — went through a doorway
      // Jumping doesn't help with gates
      _triggerHit();
      return;
    }

    // For span-all-lanes obstacles, always match
    final laneMatch = obstacle.data.spansAllLanes || playerLane == obstacleLane;
    if (!laneMatch) return;

    // Jump check
    if (obstacle.data.requiresJump && player.isJumping) return;
    if (!obstacle.data.requiresJump && player.isJumping) return;

    // Collision!
    _triggerHit();
  }

  void _triggerHit() {
    worldState.onHit();
    hitEffect.trigger();
    onStateChanged?.call();

    if (worldState.status == GameStatus.gameOver) {
      onGameOver?.call();
    }
  }

  void _checkNpcCollisions() {
    if (worldState.isInvulnerable) return;

    final playerLane = player.currentLane;

    for (final npc in npcManager.npcs) {
      if (npc.data.lane != playerLane) continue;

      final zDiff = (npc.worldZ - GameConfig.playerWorldZ).abs();
      if (zDiff > GameConfig.collisionThreshold) continue;

      // Can jump over NPCs
      if (player.isJumping) continue;

      // Collision!
      worldState.onHit();
      hitEffect.trigger();
      onStateChanged?.call();

      if (worldState.status == GameStatus.gameOver) {
        onGameOver?.call();
      }
      return; // one hit per frame
    }
  }

  void _addObstacle(ObstacleComponent obstacle) {
    _obstacles.add(obstacle);
    add(obstacle);
  }

  // Input handling
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

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
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

  void restart() {
    if (!_initialized) return;

    // Remove all obstacles
    for (final obs in _obstacles) {
      obs.removeFromParent();
    }
    _obstacles.clear();

    // Reset state
    worldState.reset();
    zoneManager.reset();
    obstacleSpawner.reset();
    npcManager.reset();
    player.currentLane = 0;
    player.isJumping = false;

    onStateChanged?.call();
  }
}
