import 'dart:math';

import '../../config/game_config.dart';
import '../zones/zone.dart';

/// A single piece of roadside scenery.
class SceneryState {
  final String modelId;
  final double worldX; // fixed X position (outside road)
  double worldZ;
  final double scale;
  final double rotY;
  final String sceneId;
  bool addedToScene = false;

  SceneryState({
    required this.modelId,
    required this.worldX,
    required this.worldZ,
    required this.scale,
    required this.rotY,
    required this.sceneId,
  });

  bool get isPastCamera => worldZ < GameConfig.nearPlane;

  void advance(double distance) {
    worldZ -= distance;
  }
}

/// Spawns and manages decorative scenery along the road edges.
class SceneryManager {
  final double Function() getDistanceTraveled;
  final double Function() getCurrentSpeed;
  final double Function() getSpeedMultiplier;
  final Zone Function() getCurrentZone;
  final Zone Function(double) getZoneAtDistance;

  final List<SceneryState> items = [];
  final Random _random = Random();
  int _nextId = 0;

  // Track the farthest Z we've placed scenery at, to avoid gaps
  double _lastSpawnZ = 0;
  static const double _spawnSpacing = 18.0; // distance between scenery pairs
  static const double _spawnVariation = 6.0; // random offset

  // Road is 9 units wide (3 lanes x 3.0), edges at +/-4.5
  // Place scenery outside the road
  static const double _minSideX = 6.0;
  static const double _maxSideX = 14.0;

  // --- Zone-specific scenery pools ---
  // Each entry: [modelId, scale, optional rotY bias]

  static const _parkingLotScenery = [
    // Parked cars on the sides
    'sedan', 'sedan-sports', 'hatchback-sports', 'taxi', 'suv', 'suv-luxury',
    'truck', 'van', 'police', 'ambulance',
    'firetruck', 'garbage-truck', 'tractor',
    // Scattered trees between parked cars
    'tree', 'tree-tall',
  ];

  static const _securityScenery = [
    'structure-gate-building', 'structure-gate', 'wall-left', 'wall-right',
    'cone', 'cone', 'support', 'support-low',
    // Sparse trees along security area
    'tree', 'tree-tall',
  ];

  static const _shopsScenery = [
    'flag-blue', 'flag-green', 'flag-red',
    'flag-large-blue', 'flag-large-green', 'flag-large-red',
    'structure-gate-building', 'windmill',
    'club-blue', 'club-green', 'club-red',
    // Decorative autumn trees lining the shops
    'tree-autumn', 'tree-autumn', 'tree-autumn-tall', 'tree-autumn-tall',
    'tree', 'tree-tall',
  ];

  static const _ticketBoothScenery = [
    'flag-blue', 'flag-green', 'flag-red',
    'flag-large-blue', 'flag-large-green', 'flag-large-red',
    'structure-gate', 'obstacle-diamond',
    'club-blue', 'club-red',
    // Trees around the ticket area
    'tree-autumn', 'tree-autumn-tall', 'tree', 'tree-tall',
  ];

  static const _walkwayScenery = [
    'flag-blue', 'flag-green', 'flag-red',
    'support-low',
    // Trees lining the walkways
    'tree', 'tree', 'tree-tall', 'tree-tall',
  ];

  static const _parkEntranceScenery = [
    'castle', 'flag-large-blue', 'flag-large-green', 'flag-large-red',
    'structure-gate-wide', 'windmill', 'structure-windmill',
    // Lush trees at the park entrance
    'tree', 'tree', 'tree-tall', 'tree-tall',
    'tree-autumn', 'tree-autumn-tall',
  ];

  // --- Landmark definitions: placed once at specific distances ---
  // [distance, modelId, side (1=right, -1=left), scale, xOffset]
  static const List<List<dynamic>> _landmarks = [
    // Security checkpoint gate buildings flanking the road
    [680.0, 'structure-gate-building', -1, 5.0, 8.0],
    [680.0, 'structure-gate-building', 1, 5.0, 8.0],

    // Large globe on the left between shops and ticket booths
    [2050.0, 'ball-red', -1, 30.0, 10.0],

    // Ticket booth buildings flanking the entrance to ticket area
    [2180.0, 'structure-gate-building', -1, 6.0, 7.0],
    [2180.0, 'structure-gate-building', 1, 6.0, 7.0],

    // Grand theme park entrance — castle on both sides, visible from far away
    [2750.0, 'castle', -1, 14.0, 12.0],
    [2750.0, 'castle', 1, 14.0, 12.0],
    // Wide gate archway at the very entrance
    [2850.0, 'structure-gate-wide', 0, 10.0, 0.0],
    // Flanking windmills at the entrance
    [2800.0, 'windmill', -1, 8.0, 16.0],
    [2800.0, 'windmill', 1, 8.0, 16.0],
  ];
  final Set<int> _placedLandmarks = {};

  SceneryManager({
    required this.getDistanceTraveled,
    required this.getCurrentSpeed,
    required this.getSpeedMultiplier,
    required this.getCurrentZone,
    required this.getZoneAtDistance,
  });

  List<String> update(double dt) {
    final speed = getCurrentSpeed() * getSpeedMultiplier();
    final moveDistance = speed * dt;
    final removedIds = <String>[];

    // Move all scenery
    for (final item in items) {
      item.advance(moveDistance);
    }

    // Remove past-camera scenery
    items.removeWhere((item) {
      if (item.isPastCamera) {
        removedIds.add(item.sceneId);
        return true;
      }
      return false;
    });

    // Spawn new scenery ahead
    _spawnAhead();

    // Place landmarks
    _checkLandmarks();

    return removedIds;
  }

  void _spawnAhead() {
    final distance = getDistanceTraveled();
    final targetZ = GameConfig.spawnDistance + 40;

    // Calculate world Z for new spawns relative to player
    while (_lastSpawnZ < distance + targetZ) {
      _lastSpawnZ += _spawnSpacing + _random.nextDouble() * _spawnVariation;
      final worldZ = _lastSpawnZ - distance;

      if (worldZ < 0) continue; // already behind camera

      final zone = getZoneAtDistance(_lastSpawnZ);
      final pool = _poolForZone(zone.type);
      if (pool.isEmpty) continue;

      // Place on both sides of the road
      for (final side in [-1.0, 1.0]) {
        // Sometimes skip one side for variety
        if (_random.nextDouble() < 0.2) continue;

        final modelId = pool[_random.nextInt(pool.length)];
        final xOffset = _minSideX + _random.nextDouble() * (_maxSideX - _minSideX);
        final scale = _scaleForModel(modelId, zone.type);
        // Face toward the road with some randomness
        final rotY = side > 0
            ? (pi * 0.4 + _random.nextDouble() * 0.4) // right side faces left-ish
            : (pi * -0.4 - _random.nextDouble() * 0.4); // left side faces right-ish

        items.add(SceneryState(
          modelId: modelId,
          worldX: side * xOffset,
          worldZ: worldZ,
          scale: scale,
          rotY: rotY,
          sceneId: 'scn_${_nextId++}',
        ));
      }
    }
  }

  void _checkLandmarks() {
    final distance = getDistanceTraveled();
    // Use a large spawn window so landmarks appear early and are visible a long time
    const spawnAhead = 220.0; // beyond normal spawn distance for early visibility
    for (int i = 0; i < _landmarks.length; i++) {
      if (_placedLandmarks.contains(i)) continue;
      final lm = _landmarks[i];
      final lmDistance = lm[0] as double;
      // Place when landmark is within extended spawn range ahead of player
      if (distance + spawnAhead > lmDistance && distance < lmDistance) {
        _placedLandmarks.add(i);
        final modelId = lm[1] as String;
        final side = lm[2] as int;
        final scale = lm[3] as double;
        final xOff = lm[4] as double;
        final worldZ = lmDistance - distance;

        items.add(SceneryState(
          modelId: modelId,
          worldX: side == 0 ? 0.0 : side * xOff,
          worldZ: worldZ,
          scale: scale,
          rotY: 0,
          sceneId: 'lmk_${_nextId++}',
        ));
      }
    }
  }

  List<String> _poolForZone(ZoneType type) {
    switch (type) {
      case ZoneType.parkingLot:
        return _parkingLotScenery;
      case ZoneType.security:
        return _securityScenery;
      case ZoneType.shops:
        return _shopsScenery;
      case ZoneType.ticketBooths:
        return _ticketBoothScenery;
      case ZoneType.walkway:
        return _walkwayScenery;
      case ZoneType.parkEntrance:
        return _parkEntranceScenery;
    }
  }

  double _scaleForModel(String modelId, ZoneType zone) {
    // Vehicles in parking lot — scale to look like parked cars
    if (_parkingLotScenery.contains(modelId) && zone == ZoneType.parkingLot) {
      if (['firetruck', 'garbage-truck', 'tractor'].contains(modelId)) {
        return 2.8 + _random.nextDouble() * 0.5;
      }
      return 2.0 + _random.nextDouble() * 0.6;
    }
    // Flags
    if (modelId.startsWith('flag-large')) return 3.5 + _random.nextDouble() * 1.0;
    if (modelId.startsWith('flag')) return 2.5 + _random.nextDouble() * 0.5;
    // Structures
    if (modelId.startsWith('structure')) return 3.0 + _random.nextDouble() * 1.0;
    if (modelId == 'castle') return 5.0 + _random.nextDouble() * 1.0;
    if (modelId == 'windmill' || modelId == 'structure-windmill') {
      return 3.5 + _random.nextDouble() * 1.0;
    }
    // Trees — tall variants are bigger
    if (modelId == 'tree-tall' || modelId == 'tree-autumn-tall') {
      return 4.0 + _random.nextDouble() * 2.0;
    }
    if (modelId.startsWith('tree')) return 3.0 + _random.nextDouble() * 1.5;
    // Clubs, balls
    if (modelId.startsWith('club')) return 3.0 + _random.nextDouble() * 0.5;
    if (modelId.startsWith('ball')) return 5.0;
    // Walls, supports
    if (modelId.startsWith('wall')) return 2.5;
    if (modelId.startsWith('support')) return 2.0 + _random.nextDouble() * 0.5;
    // Default
    return 2.0 + _random.nextDouble() * 0.5;
  }

  void reset() {
    items.clear();
    _lastSpawnZ = 0;
    _placedLandmarks.clear();
  }
}
