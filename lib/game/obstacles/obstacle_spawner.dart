import 'dart:math';

import '../../config/game_config.dart';
import '../components/obstacle.dart';
import '../perspective.dart';
import '../zones/zone_manager.dart';
import 'obstacle_data.dart';

/// Spawns obstacles based on current zone configuration.
class ObstacleSpawner {
  final ZoneManager zoneManager;
  final PerspectiveProjection perspective;
  final void Function(ObstacleComponent) onSpawn;
  final Random _random = Random();

  double _spawnTimer = 0;
  double _currentInterval = 1.5;
  double _timeSinceLastGate = 0;

  ObstacleSpawner({
    required this.zoneManager,
    required this.perspective,
    required this.onSpawn,
  });

  void update(double dt) {
    final zone = zoneManager.currentZone;
    if (zone.obstaclePool.isEmpty) return;

    _timeSinceLastGate += dt;
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawn();
      _currentInterval = zone.spawnIntervalMin +
          _random.nextDouble() *
              (zone.spawnIntervalMax - zone.spawnIntervalMin);
      _spawnTimer = _currentInterval;
    }
  }

  void _spawn() {
    final zone = zoneManager.currentZone;
    if (zone.obstaclePool.isEmpty) return;

    // In security zone, occasionally spawn a security gate instead
    if (zone.obstaclePool.contains(ObstacleData.metalDetector) &&
        _timeSinceLastGate > 6.0 &&
        _random.nextDouble() < 0.25) {
      _spawnSecurityGate();
      return;
    }

    // Pick random obstacle from pool
    final data = zone.obstaclePool[_random.nextInt(zone.obstaclePool.length)];

    if (data.spansAllLanes) {
      // Single obstacle in center lane (jump-only)
      final obstacle = ObstacleComponent(
        data: data,
        lane: 0,
        worldZ: GameConfig.spawnDistance,
        perspective: perspective,
      );
      onSpawn(obstacle);
    } else {
      // Pick pattern
      final pattern = _random.nextDouble();
      if (pattern < 0.5) {
        // Single obstacle in random lane
        _spawnSingle(data);
      } else if (pattern < 0.8) {
        // Double obstacle (two lanes blocked)
        _spawnDouble(data);
      } else {
        // Staggered (two obstacles at different depths)
        _spawnStaggered(data);
      }
    }
  }

  void _spawnSecurityGate() {
    final blockedLane = _random.nextInt(3) - 1; // -1, 0, or 1
    onSpawn(ObstacleComponent(
      data: ObstacleData.securityGate,
      lane: 0,
      worldZ: GameConfig.spawnDistance,
      perspective: perspective,
      blockedLane: blockedLane,
    ));
    _timeSinceLastGate = 0;
  }

  void _spawnSingle(ObstacleData data) {
    final lane = _random.nextInt(3) - 1;
    onSpawn(ObstacleComponent(
      data: data,
      lane: lane,
      worldZ: GameConfig.spawnDistance,
      perspective: perspective,
    ));
  }

  void _spawnDouble(ObstacleData data) {
    final lanes = [-1, 0, 1]..shuffle(_random);
    // Block two lanes, leave one free
    for (int i = 0; i < 2; i++) {
      onSpawn(ObstacleComponent(
        data: data,
        lane: lanes[i],
        worldZ: GameConfig.spawnDistance,
        perspective: perspective,
      ));
    }
  }

  void _spawnStaggered(ObstacleData data) {
    final lane1 = _random.nextInt(3) - 1;
    int lane2 = _random.nextInt(3) - 1;
    while (lane2 == lane1) {
      lane2 = _random.nextInt(3) - 1;
    }

    onSpawn(ObstacleComponent(
      data: data,
      lane: lane1,
      worldZ: GameConfig.spawnDistance,
      perspective: perspective,
    ));
    onSpawn(ObstacleComponent(
      data: data,
      lane: lane2,
      worldZ: GameConfig.spawnDistance + 15, // offset in depth
      perspective: perspective,
    ));
  }

  void reset() {
    _spawnTimer = 2.0; // brief grace period at start
    _timeSinceLastGate = 0;
  }
}
