import 'dart:math';
import 'dart:ui';

import '../../config/game_config.dart';
import '../../config/theme.dart';
import '../components/npc_state.dart';
import '../components/obstacle_state.dart';
import '../components/player_state.dart';
import '../components/scenery_state.dart';
import '../obstacles/obstacle_data.dart';
import '../world_state.dart';
import '../zones/zone.dart';
import '../zones/zone_manager.dart';
import 'camera_config.dart';
import 'model_manager.dart';
import 'three_bridge.dart';

/// Scale factors for 3D models.
///
/// Asset pack models are typically ~1 unit in size.
/// Game lanes are 3.0 world units wide, so models need scaling up.
class _ModelScale {
  // Player character: ~1.8 units tall, facing +Z (down the road)
  static const double playerScale = 1.8;
  static const double playerRotY = 0; // model faces +Z by default (away from camera)

  // NPC characters: slightly smaller than player
  static const double npcScale = 1.5;

  // Vehicle obstacles: should nearly fill a lane (~2.5 units wide)
  static const double vehicleScale = 2.5;

  // Small obstacles (cones, debris): smaller
  static const double smallObstacleScale = 1.5;

  // Structure obstacles (gates, kiosks): taller
  static const double structureScale = 2.8;

  // Full-road obstacles (speed bumps, benches): wide
  static const double wideObstacleScale = 2.0;

  /// Get the scale for an obstacle type.
  static double forObstacle(ObstacleType type) {
    switch (type) {
      case ObstacleType.car:
        return vehicleScale;
      case ObstacleType.shoppingCart:
        return smallObstacleScale;
      case ObstacleType.speedBump:
        return wideObstacleScale;
      case ObstacleType.barricade:
        return smallObstacleScale;
      case ObstacleType.metalDetector:
        return structureScale;
      case ObstacleType.bagCheckStation:
        return vehicleScale;
      case ObstacleType.securityGate:
        return structureScale;
      case ObstacleType.merchandiseRack:
        return vehicleScale;
      case ObstacleType.foodCart:
        return vehicleScale;
      case ObstacleType.bench:
        return wideObstacleScale;
      case ObstacleType.ropeLine:
        return smallObstacleScale;
      case ObstacleType.turnstile:
        return structureScale;
      case ObstacleType.ticketKiosk:
        return structureScale;
    }
  }
}

/// Syncs game state to the three.js scene graph once per frame.
class SceneSync {
  final ThreeBridge _bridge;
  final double screenWidth;
  final double screenHeight;

  ZoneType? _lastZoneType;
  double _scrollAccumulator = 0;
  bool _playerAdded = false;
  bool _playerModelReady = false;

  SceneSync({
    required this.screenWidth,
    required this.screenHeight,
    ThreeBridge? bridge,
  }) : _bridge = bridge ?? ThreeBridge.instance;

  /// Build and send the per-frame scene update.
  void sync({
    required PlayerState player,
    required List<ObstacleState> obstacles,
    required NpcManager npcManager,
    required SceneryManager sceneryManager,
    required WorldState worldState,
    required ZoneManager zoneManager,
    required List<String> removedNpcIds,
    required List<String> removedSceneryIds,
    required double dt,
  }) {
    final update = <String, dynamic>{};

    // --- Camera ---
    update['camera'] =
        CameraConfig.buildCameraUpdate(screenWidth, screenHeight);

    // --- Player ---
    final playerUpdates = <String, dynamic>{
      'id': 'player',
      'x': -player.worldX,
      'y': player.jumpHeight,
      'z': GameConfig.playerWorldZ.toDouble(),
      'visible': player.isVisibleThisFrame,
      'anim': player.animationState,
      'animLoop': player.animationState == 'sprint',
    };

    // If player was added as fallback, check if the real model is now loaded
    if (_playerAdded && !_playerModelReady) {
      if (_bridge.isModelLoaded(ModelManager.playerModelId)) {
        // Remove the fallback box and re-add with the real model
        update['remove'] = <String>['player'];
        update['add'] = <Map<String, dynamic>>[
          {
            'id': 'player',
            'modelId': ModelManager.playerModelId,
            'x': -player.worldX,
            'y': player.jumpHeight,
            'z': GameConfig.playerWorldZ,
            'scaleX': _ModelScale.playerScale,
            'scaleY': _ModelScale.playerScale,
            'scaleZ': _ModelScale.playerScale,
            'rotY': _ModelScale.playerRotY,
            'anim': 'sprint',
            'animLoop': true,
            'fallbackColor': 0x00E5FF,
          },
        ];
        _playerModelReady = true;
      }
    }

    if (!_playerAdded) {
      final modelReady =
          _bridge.isModelLoaded(ModelManager.playerModelId);
      update['add'] = <Map<String, dynamic>>[
        {
          'id': 'player',
          'modelId': ModelManager.playerModelId,
          'x': -player.worldX,
          'y': player.jumpHeight,
          'z': GameConfig.playerWorldZ,
          'scaleX': _ModelScale.playerScale,
          'scaleY': _ModelScale.playerScale,
          'scaleZ': _ModelScale.playerScale,
          'rotY': _ModelScale.playerRotY,
          'anim': 'run',
          'animLoop': true,
          'fallbackColor': 0x00E5FF,
        },
      ];
      _playerAdded = true;
      _playerModelReady = modelReady;
    }

    // --- Obstacles ---
    final adds = <Map<String, dynamic>>[];
    final updates = <Map<String, dynamic>>[];
    final removes = <String>[];

    for (final obs in obstacles) {
      if (!obs.addedToScene) {
        final scale = _ModelScale.forObstacle(obs.data.type);
        final spansAll = obs.data.spansAllLanes && !obs.data.blocksJump;
        adds.add({
          'id': obs.sceneId,
          'modelId': ModelManager.obstacleModelId(obs.data.type),
          'x': -obs.worldX,
          'y': 0,
          'z': obs.worldZ,
          'scaleX': scale,
          'scaleY': scale,
          'scaleZ': scale,
          'fallbackColor': obs.data.color.value,
          if (spansAll) 'spanLanes': true,
          if (spansAll) 'laneWidth': GameConfig.laneWidth,
        });
        obs.addedToScene = true;
      } else {
        updates.add({
          'id': obs.sceneId,
          'x': -obs.worldX,
          'y': 0,
          'z': obs.worldZ,
        });
      }
    }

    // --- NPCs ---
    for (final npc in npcManager.npcs) {
      if (!npc.addedToScene) {
        // NPCs facing camera rotate pi (turn around), facing away rotate 0
        final rotY = npc.facingCamera ? pi : 0.0;
        adds.add({
          'id': npc.sceneId,
          'modelId': ModelManager.npcModelId(npc.data.type),
          'x': -npc.worldX,
          'y': 0,
          'z': npc.worldZ,
          'scaleX': _ModelScale.npcScale,
          'scaleY': _ModelScale.npcScale,
          'scaleZ': _ModelScale.npcScale,
          'rotY': rotY,
          'anim': npc.animationState,
          'animLoop': true,
          'fallbackColor': npc.data.bodyColor.value,
        });
        npc.addedToScene = true;
      } else {
        updates.add({
          'id': npc.sceneId,
          'x': -npc.worldX,
          'y': 0,
          'z': npc.worldZ,
        });
      }
    }

    // Removed NPCs
    removes.addAll(removedNpcIds);

    // --- Scenery ---
    for (final scn in sceneryManager.items) {
      if (!scn.addedToScene) {
        adds.add({
          'id': scn.sceneId,
          'modelId': scn.modelId,
          'x': -scn.worldX, // negate for camera coordinate system
          'y': 0,
          'z': scn.worldZ,
          'scaleX': scn.scale,
          'scaleY': scn.scale,
          'scaleZ': scn.scale,
          'rotY': scn.rotY,
          'fallbackColor': 0x666666,
        });
        scn.addedToScene = true;
      } else {
        updates.add({
          'id': scn.sceneId,
          'x': -scn.worldX,
          'y': 0,
          'z': scn.worldZ,
        });
      }
    }

    // Removed scenery
    removes.addAll(removedSceneryIds);

    // Player update (every frame)
    updates.add(playerUpdates);

    if (adds.isNotEmpty) {
      update['add'] = [...(update['add'] as List? ?? []), ...adds];
    }
    if (updates.isNotEmpty) update['update'] = updates;
    if (removes.isNotEmpty) {
      update['remove'] = [
        ...(update['remove'] as List? ?? []),
        ...removes,
      ];
    }

    // --- Walkway Z-range clipping (every frame) ---
    final walkwayRanges = <Map<String, double>>[];
    for (final z in zoneManager.zones) {
      if (!z.isWalkway) continue;
      // Convert zone world distances to camera-relative Z
      final startZ = z.startDistance - worldState.distanceTraveled + GameConfig.playerWorldZ;
      final endZ = z.endDistance - worldState.distanceTraveled + GameConfig.playerWorldZ;
      // Only include if any part is in the visible range
      if (endZ > -5 && startZ < 240) {
        walkwayRanges.add({'startZ': startZ, 'endZ': endZ});
      }
    }
    update['walkwayRanges'] = walkwayRanges;

    // --- Zone visuals ---
    final zone = zoneManager.currentZone;
    if (_lastZoneType != zone.type) {
      _lastZoneType = zone.type;
      update['zone'] = {
        'groundColor': _colorToHex(zone.groundColor),
        'roadColor': _colorToHex(zone.roadColor),
        'fogColor': _colorToHex(_fogColorForZone(zone.type)),
        'ambientColor': _colorToHex(_ambientColorForZone(zone.type)),
        'isWalkway': zone.isWalkway,
      };
    }

    // --- Ground scroll ---
    final scrollDist =
        worldState.currentSpeed * worldState.zoneSpeedMultiplier * dt;
    _scrollAccumulator += scrollDist;
    update['scrollOffset'] = scrollDist * 0.3;

    _bridge.syncScene(update);
    _bridge.renderFrame();
  }

  /// Remove specific obstacle IDs from the scene.
  void removeObstacles(List<String> ids) {
    if (ids.isEmpty) return;
    _bridge.syncScene({'remove': ids});
  }

  /// Trigger the hit flash effect.
  void triggerHitFlash() {
    _bridge.syncScene({
      'effects': {'hitFlash': true},
    });
  }

  /// Reset for a new game.
  void reset() {
    _lastZoneType = null;
    _scrollAccumulator = 0;
    _playerAdded = false;
    _playerModelReady = false;
  }

  Color _ambientColorForZone(ZoneType type) {
    switch (type) {
      case ZoneType.parkingLot:
        return GameTheme.parkingLotAmbient;
      case ZoneType.security:
        return GameTheme.securityAmbient;
      case ZoneType.shops:
        return GameTheme.shopsAmbient;
      case ZoneType.ticketBooths:
        return GameTheme.ticketBoothsAmbient;
      case ZoneType.walkway:
        return GameTheme.walkwayAmbient;
      case ZoneType.parkEntrance:
        return GameTheme.parkEntranceAmbient;
    }
  }

  Color _fogColorForZone(ZoneType type) {
    switch (type) {
      case ZoneType.parkingLot:
        return GameTheme.parkingLotFog;
      case ZoneType.security:
        return GameTheme.securityFog;
      case ZoneType.shops:
        return GameTheme.shopsFog;
      case ZoneType.ticketBooths:
        return GameTheme.ticketBoothsFog;
      case ZoneType.walkway:
        return GameTheme.walkwayFog;
      case ZoneType.parkEntrance:
        return GameTheme.parkEntranceFog;
    }
  }

  String _colorToHex(dynamic color) {
    if (color is int) return '#${color.toRadixString(16).padLeft(6, '0')}';
    final c = color as dynamic;
    final r = ((c.r as double) * 255).round();
    final g = ((c.g as double) * 255).round();
    final b = ((c.b as double) * 255).round();
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }
}
