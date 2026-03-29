import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../config/game_config.dart';
import '../perspective.dart';
import '../zones/zone.dart';

enum NpcType {
  walkingSame, // walking in the player's direction
  walkingOpposite, // walking toward the player
  stationary, // standing still (security guards)
}

class NpcData {
  final NpcType type;
  final int lane; // -1, 0, 1
  final Color bodyColor;
  final Color headColor;
  final Color legColor;
  final double walkSpeed; // world units per second (relative to ground)

  const NpcData({
    required this.type,
    required this.lane,
    required this.bodyColor,
    required this.headColor,
    required this.legColor,
    this.walkSpeed = 0,
  });
}

class NpcComponent extends Component {
  final NpcData data;
  final PerspectiveProjection perspective;
  double worldZ;
  double _animTimer = 0;

  NpcComponent({
    required this.data,
    required this.perspective,
    required this.worldZ,
  });

  double get worldX => data.lane * GameConfig.laneWidth;
  bool get isPastCamera => worldZ < GameConfig.nearPlane;
  bool get isTooFar => worldZ > GameConfig.farPlane;

  @override
  int get priority => -(worldZ * 10).toInt();

  void advance(double distance) {
    worldZ -= distance;
  }

  void updateNpc(double dt) {
    _animTimer += dt;
    // NPCs walking same direction move slower than world scroll,
    // so they appear to drift toward the camera slightly less fast.
    // NPCs walking opposite move faster toward the camera.
    // Stationary ones just get scrolled by the world movement.
    if (data.type == NpcType.walkingSame) {
      worldZ += data.walkSpeed * dt; // partially counteract the scroll
    } else if (data.type == NpcType.walkingOpposite) {
      worldZ -= data.walkSpeed * dt; // add to the scroll
    }
  }

  @override
  void render(Canvas canvas) {
    final projected = perspective.project(worldX, 0, worldZ);
    if (projected == null) return;
    if (worldZ > GameConfig.farPlane) return;

    final scale = projected.scale * 0.08;
    final cx = projected.x;
    final baseY = projected.y;

    if (scale < 0.05) return; // too small to see

    final bodyHeight = 28 * scale;
    final bodyWidth = 12 * scale;
    final headRadius = 6 * scale;
    final legLength = 9 * scale;
    final legWidth = 3.5 * scale;

    // Walking animation - leg sway
    double leftLegOffset = 0;
    double rightLegOffset = 0;
    if (data.type != NpcType.stationary) {
      final walkCycle = sin(_animTimer * 6);
      leftLegOffset = walkCycle * legLength * 0.3;
      rightLegOffset = -walkCycle * legLength * 0.3;
    }

    // Legs
    final legPaint = Paint()..color = data.legColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(
              cx - bodyWidth * 0.2, baseY - legLength / 2 + leftLegOffset),
          width: legWidth,
          height: legLength,
        ),
        Radius.circular(2 * scale),
      ),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(
              cx + bodyWidth * 0.2, baseY - legLength / 2 + rightLegOffset),
          width: legWidth,
          height: legLength,
        ),
        Radius.circular(2 * scale),
      ),
      legPaint,
    );

    // Body
    final bodyPaint = Paint()..color = data.bodyColor;
    final bodyTop = baseY - legLength - bodyHeight;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - bodyWidth / 2,
          bodyTop,
          bodyWidth,
          bodyHeight,
        ),
        Radius.circular(3 * scale),
      ),
      bodyPaint,
    );

    // Head
    canvas.drawCircle(
      Offset(cx, bodyTop - headRadius * 0.5),
      headRadius,
      Paint()..color = data.headColor,
    );
  }
}

/// Manages spawning and updating of NPC characters.
class NpcManager extends Component {
  final PerspectiveProjection perspective;
  final double Function() getDistanceTraveled;
  final double Function() getCurrentSpeed;
  final double Function() getSpeedMultiplier;
  final Zone Function() getCurrentZone;
  final Zone Function(double) getZoneAtDistance;

  final List<NpcComponent> _npcs = [];
  List<NpcComponent> get npcs => _npcs;
  final Random _random = Random();
  double _spawnTimer = 0;

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
    Color(0xFF546E7A), // blue grey
    Color(0xFF8D6E63), // brown
    Color(0xFF78909C), // grey
    Color(0xFF5C6BC0), // indigo
    Color(0xFF26A69A), // teal
    Color(0xFFAB47BC), // purple
    Color(0xFFEF5350), // red
    Color(0xFF66BB6A), // green
    Color(0xFFFF7043), // deep orange
    Color(0xFF29B6F6), // light blue
  ];

  // Security guard color
  static const _securityBodyColor = Color(0xFF1A237E); // dark navy
  static const _securityLegColor = Color(0xFF0D1642);

  NpcManager({
    required this.perspective,
    required this.getDistanceTraveled,
    required this.getCurrentSpeed,
    required this.getSpeedMultiplier,
    required this.getCurrentZone,
    required this.getZoneAtDistance,
  });

  @override
  void update(double dt) {
    super.update(dt);

    final speed = getCurrentSpeed() * getSpeedMultiplier();
    final moveDistance = speed * dt;

    // Update and cull NPCs
    final toRemove = <NpcComponent>[];
    for (final npc in _npcs) {
      npc.advance(moveDistance);
      npc.updateNpc(dt);
      if (npc.isPastCamera || npc.isTooFar) {
        toRemove.add(npc);
      }
    }
    for (final npc in toRemove) {
      npc.removeFromParent();
      _npcs.remove(npc);
    }

    // Spawn new NPCs
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _trySpawn();
      _spawnTimer = 0.3 + _random.nextDouble() * 0.5;
    }
  }

  void _trySpawn() {
    final distance = getDistanceTraveled();
    final zone = getCurrentZone();

    // Don't spawn in park entrance
    if (zone.type == ZoneType.parkEntrance) return;

    // Limit NPC count
    if (_npcs.length >= 20) return;

    final spawnZ = GameConfig.spawnDistance + _random.nextDouble() * 40;
    final spawnZone = getZoneAtDistance(distance + spawnZ);

    // Decide NPC type based on zone
    NpcType type;
    if (spawnZone.type == ZoneType.security) {
      // Mostly stationary security, some walkers
      final roll = _random.nextDouble();
      if (roll < 0.45) {
        type = NpcType.stationary;
      } else if (roll < 0.75) {
        type = NpcType.walkingSame;
      } else {
        type = NpcType.walkingOpposite;
      }
    } else {
      // Mostly walkers
      final roll = _random.nextDouble();
      if (roll < 0.5) {
        type = NpcType.walkingSame;
      } else {
        type = NpcType.walkingOpposite;
      }
    }

    // Pick a lane — avoid center (lane 0) more often to not block the player
    final laneRoll = _random.nextDouble();
    int lane;
    if (laneRoll < 0.35) {
      lane = -1;
    } else if (laneRoll < 0.7) {
      lane = 1;
    } else {
      lane = 0;
    }

    // Offset within lane so they don't stack on lane centers
    final skinTone = _skinTones[_random.nextInt(_skinTones.length)];

    Color bodyColor;
    Color legColor;
    if (type == NpcType.stationary) {
      bodyColor = _securityBodyColor;
      legColor = _securityLegColor;
    } else {
      bodyColor = _bodyColors[_random.nextInt(_bodyColors.length)];
      legColor = Color.lerp(bodyColor, Colors.black, 0.3)!;
    }

    final walkSpeed = type == NpcType.stationary
        ? 0.0
        : (3.0 + _random.nextDouble() * 5.0);

    final npcData = NpcData(
      type: type,
      lane: lane,
      bodyColor: bodyColor,
      headColor: skinTone,
      legColor: legColor,
      walkSpeed: walkSpeed,
    );

    final npc = NpcComponent(
      data: npcData,
      perspective: perspective,
      worldZ: spawnZ,
    );

    _npcs.add(npc);
    parent?.add(npc);
  }

  void reset() {
    for (final npc in _npcs) {
      npc.removeFromParent();
    }
    _npcs.clear();
    _spawnTimer = 1.0;
  }
}
