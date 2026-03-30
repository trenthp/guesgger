import 'dart:math';
import 'dart:ui';

import '../../config/game_config.dart';
import '../zones/zone.dart';

/// NPC type — determines movement pattern.
enum NpcType {
  walkingSame,
  walkingOpposite,
  stationary,
}

/// NPC data — immutable properties set at spawn time.
class NpcData {
  final NpcType type;
  final int lane;
  final Color bodyColor;
  final Color headColor;
  final Color legColor;
  final double walkSpeed;

  const NpcData({
    required this.type,
    required this.lane,
    required this.bodyColor,
    required this.headColor,
    required this.legColor,
    this.walkSpeed = 0,
  });
}

/// Pure-Dart NPC state — no rendering, no Flame dependency.
class NpcState {
  final NpcData data;
  double worldZ;
  double animTimer = 0;

  /// Unique ID for the three.js scene object.
  final String sceneId;

  /// Whether this NPC has been added to the three.js scene.
  bool addedToScene = false;

  NpcState({
    required this.data,
    required this.worldZ,
    required this.sceneId,
  });

  double get worldX => data.lane * GameConfig.laneWidth;
  bool get isPastCamera => worldZ < GameConfig.nearPlane;
  bool get isTooFar => worldZ > GameConfig.farPlane;

  String get animationState {
    if (data.type == NpcType.stationary) return 'idle';
    return 'walk';
  }

  /// Facing direction: true = facing camera (opposite walkers), false = facing away.
  bool get facingCamera => data.type == NpcType.walkingOpposite;

  void advance(double distance) {
    worldZ -= distance;
  }

  void update(double dt) {
    animTimer += dt;
    if (data.type == NpcType.walkingSame) {
      worldZ += data.walkSpeed * dt;
    } else if (data.type == NpcType.walkingOpposite) {
      worldZ -= data.walkSpeed * dt;
    }
  }
}

/// Manages NPC spawning and lifecycle — pure Dart, no Flame.
class NpcManager {
  final double Function() getDistanceTraveled;
  final double Function() getCurrentSpeed;
  final double Function() getSpeedMultiplier;
  final Zone Function() getCurrentZone;
  final Zone Function(double) getZoneAtDistance;

  final List<NpcState> npcs = [];
  final Random _random = Random();
  double _spawnTimer = 1.0;
  int _nextId = 0;

  // Skin tone palette
  static const _skinTones = [
    Color(0xFFFFDBAC),
    Color(0xFFFFCC80),
    Color(0xFFD4A373),
    Color(0xFFA67B5B),
    Color(0xFF8D5524),
    Color(0xFF6B3A2A),
  ];

  // Casual clothing colors
  static const _bodyColors = [
    Color(0xFF546E7A),
    Color(0xFF8D6E63),
    Color(0xFF78909C),
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFAB47BC),
    Color(0xFFEF5350),
    Color(0xFF66BB6A),
    Color(0xFFFF7043),
    Color(0xFF29B6F6),
  ];

  static const _securityBodyColor = Color(0xFF1A237E);
  static const _securityLegColor = Color(0xFF0D1642);

  NpcManager({
    required this.getDistanceTraveled,
    required this.getCurrentSpeed,
    required this.getSpeedMultiplier,
    required this.getCurrentZone,
    required this.getZoneAtDistance,
  });

  /// Update all NPCs and spawn new ones. Returns lists of IDs
  /// that were removed this frame (for scene cleanup).
  List<String> update(double dt) {
    final speed = getCurrentSpeed() * getSpeedMultiplier();
    final moveDistance = speed * dt;
    final removedIds = <String>[];

    for (final npc in npcs) {
      npc.advance(moveDistance);
      npc.update(dt);
    }

    npcs.removeWhere((npc) {
      if (npc.isPastCamera || npc.isTooFar) {
        removedIds.add(npc.sceneId);
        return true;
      }
      return false;
    });

    // Spawn
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _trySpawn();
      _spawnTimer = 0.3 + _random.nextDouble() * 0.5;
    }

    return removedIds;
  }

  void _trySpawn() {
    final distance = getDistanceTraveled();
    final zone = getCurrentZone();

    if (zone.type == ZoneType.parkEntrance) return;
    if (npcs.length >= 20) return;

    final spawnZ = GameConfig.spawnDistance + _random.nextDouble() * 40;
    final spawnZone = getZoneAtDistance(distance + spawnZ);

    // Decide whether to spawn a group (30% chance) or single NPC
    final groupRoll = _random.nextDouble();
    if (groupRoll < 0.30 && npcs.length <= 16) {
      _spawnGroup(spawnZ, spawnZone);
    } else {
      _spawnSingle(spawnZ, spawnZone);
    }
  }

  void _spawnSingle(double spawnZ, Zone spawnZone) {
    NpcType type;
    if (spawnZone.type == ZoneType.security) {
      final roll = _random.nextDouble();
      if (roll < 0.40) {
        type = NpcType.stationary;
      } else if (roll < 0.70) {
        type = NpcType.walkingSame;
      } else {
        type = NpcType.walkingOpposite;
      }
    } else {
      final roll = _random.nextDouble();
      if (roll < 0.40) {
        type = NpcType.walkingSame;
      } else if (roll < 0.70) {
        type = NpcType.walkingOpposite;
      } else {
        type = NpcType.stationary;
      }
    }

    final lane = _randomLane();
    _addNpc(type: type, lane: lane, worldZ: spawnZ);
  }

  /// Spawn a group of 2-4 NPCs close together.
  void _spawnGroup(double spawnZ, Zone spawnZone) {
    final groupSize = 2 + _random.nextInt(3); // 2-4 NPCs

    // Groups share a movement type and general direction
    final groupRoll = _random.nextDouble();
    NpcType groupType;
    if (spawnZone.type == ZoneType.security) {
      groupType = groupRoll < 0.5 ? NpcType.stationary : NpcType.walkingSame;
    } else {
      if (groupRoll < 0.45) {
        groupType = NpcType.walkingSame;
      } else if (groupRoll < 0.80) {
        groupType = NpcType.walkingOpposite;
      } else {
        groupType = NpcType.stationary;
      }
    }

    // Groups share a base speed (with small per-member variation)
    final baseGroupSpeed = groupType == NpcType.stationary
        ? 0.0
        : (2.0 + _random.nextDouble() * 6.0);

    // Pick a primary lane — group members can spill into adjacent lane
    final primaryLane = _randomLane();

    for (int i = 0; i < groupSize; i++) {
      // Spread members along Z with small offsets (close together)
      final zOffset = _random.nextDouble() * 4.0 - 1.0; // -1 to +3
      // Most stay in primary lane, some drift to adjacent
      int lane = primaryLane;
      if (i > 0 && _random.nextDouble() < 0.3) {
        lane = (primaryLane + (_random.nextBool() ? 1 : -1)).clamp(-1, 1);
      }
      // Small speed variation within group
      final speedVariation = groupType == NpcType.stationary
          ? 0.0
          : (baseGroupSpeed + (_random.nextDouble() * 2.0 - 1.0)).clamp(1.0, 10.0);

      _addNpc(
        type: groupType,
        lane: lane,
        worldZ: spawnZ + zOffset,
        walkSpeed: speedVariation,
      );
    }
  }

  int _randomLane() {
    final laneRoll = _random.nextDouble();
    if (laneRoll < 0.35) return -1;
    if (laneRoll < 0.70) return 1;
    return 0;
  }

  void _addNpc({
    required NpcType type,
    required int lane,
    required double worldZ,
    double? walkSpeed,
  }) {
    final skinTone = _skinTones[_random.nextInt(_skinTones.length)];
    Color bodyColor;
    Color legColor;
    if (type == NpcType.stationary) {
      bodyColor = _securityBodyColor;
      legColor = _securityLegColor;
    } else {
      bodyColor = _bodyColors[_random.nextInt(_bodyColors.length)];
      legColor = Color.lerp(bodyColor, const Color(0xFF000000), 0.3)!;
    }

    final speed = walkSpeed ??
        (type == NpcType.stationary ? 0.0 : (2.0 + _random.nextDouble() * 8.0));

    final npcData = NpcData(
      type: type,
      lane: lane,
      bodyColor: bodyColor,
      headColor: skinTone,
      legColor: legColor,
      walkSpeed: speed,
    );

    npcs.add(NpcState(
      data: npcData,
      worldZ: worldZ,
      sceneId: 'npc_${_nextId++}',
    ));
  }

  void reset() {
    npcs.clear();
    _spawnTimer = 1.0;
  }
}
