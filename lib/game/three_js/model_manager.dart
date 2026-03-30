import 'dart:math';

import '../components/npc_state.dart';
import '../obstacles/obstacle_data.dart';
import 'three_bridge.dart';

/// Maps game object types to GLB model IDs and handles preloading.
///
/// Uses the actual asset filenames from the model pack without renaming.
class ModelManager {
  final ThreeBridge _bridge;
  static final _random = Random();

  ModelManager({ThreeBridge? bridge})
      : _bridge = bridge ?? ThreeBridge.instance;

  // --- Asset path constants ---
  static const _base = 'assets/assets/models';

  /// All model IDs and their paths.
  static const _modelPaths = <String, String>{
    // Player
    'character-e': '$_base/player/character-e.glb',

    // NPC characters
    'character-a': '$_base/npcs/character-a.glb',
    'character-b': '$_base/npcs/character-b.glb',
    'character-c': '$_base/npcs/character-c.glb',
    'character-d': '$_base/npcs/character-d.glb',
    'character-f': '$_base/npcs/character-f.glb',
    'character-g': '$_base/npcs/character-g.glb',
    'character-h': '$_base/npcs/character-h.glb',
    'character-i': '$_base/npcs/character-i.glb',
    'character-j': '$_base/npcs/character-j.glb',
    'character-k': '$_base/npcs/character-k.glb',
    'character-l': '$_base/npcs/character-l.glb',
    'character-m': '$_base/npcs/character-m.glb',
    'character-n': '$_base/npcs/character-n.glb',
    'character-o': '$_base/npcs/character-o.glb',
    'character-p': '$_base/npcs/character-p.glb',
    'character-q': '$_base/npcs/character-q.glb',
    'character-r': '$_base/npcs/character-r.glb',

    // Obstacle vehicles
    'sedan': '$_base/obstacles/sedan.glb',
    'sedan-sports': '$_base/obstacles/sedan-sports.glb',
    'hatchback-sports': '$_base/obstacles/hatchback-sports.glb',
    'taxi': '$_base/obstacles/taxi.glb',
    'police': '$_base/obstacles/police.glb',
    'ambulance': '$_base/obstacles/ambulance.glb',
    'suv': '$_base/obstacles/suv.glb',
    'suv-luxury': '$_base/obstacles/suv-luxury.glb',
    'van': '$_base/obstacles/van.glb',
    'truck': '$_base/obstacles/truck.glb',
    'truck-flat': '$_base/obstacles/truck-flat.glb',
    'delivery': '$_base/obstacles/delivery.glb',
    'delivery-flat': '$_base/obstacles/delivery-flat.glb',
    'firetruck': '$_base/obstacles/firetruck.glb',
    'garbage-truck': '$_base/obstacles/garbage-truck.glb',
    'tractor': '$_base/obstacles/tractor.glb',
    'tractor-police': '$_base/obstacles/tractor-police.glb',
    'tractor-shovel': '$_base/obstacles/tractor-shovel.glb',
    'race': '$_base/obstacles/race.glb',
    'race-future': '$_base/obstacles/race-future.glb',

    // Obstacle props
    'cone': '$_base/obstacles/cone.glb',
    'cone-flat': '$_base/obstacles/cone-flat.glb',
    'box': '$_base/obstacles/box.glb',

    // Obstacle debris
    'debris-tire': '$_base/obstacles/debris-tire.glb',
    'debris-bumper': '$_base/obstacles/debris-bumper.glb',
    'debris-door': '$_base/obstacles/debris-door.glb',
    'debris-spoiler-a': '$_base/obstacles/debris-spoiler-a.glb',
    'debris-plate-a': '$_base/obstacles/debris-plate-a.glb',

    // Karts
    'kart-oobi': '$_base/obstacles/kart-oobi.glb',
    'kart-oodi': '$_base/obstacles/kart-oodi.glb',
    'kart-ooli': '$_base/obstacles/kart-ooli.glb',
    'kart-oopi': '$_base/obstacles/kart-oopi.glb',
    'kart-oozi': '$_base/obstacles/kart-oozi.glb',

    // Environment structures
    'structure-gate': '$_base/environment/structure-gate.glb',
    'structure-gate-wide': '$_base/environment/structure-gate-wide.glb',
    'structure-gates': '$_base/environment/structure-gates.glb',
    'structure-gate-building': '$_base/environment/structure-gate-building.glb',
    'castle': '$_base/environment/castle.glb',
    'windmill': '$_base/environment/windmill.glb',
    'structure-windmill': '$_base/environment/structure-windmill.glb',
    'obstacle-block': '$_base/environment/obstacle-block.glb',
    'obstacle-diamond': '$_base/environment/obstacle-diamond.glb',
    'obstacle-triangle': '$_base/environment/obstacle-triangle.glb',
    'tunnel-wide': '$_base/environment/tunnel-wide.glb',
    'tunnel-narrow': '$_base/environment/tunnel-narrow.glb',
    'straight': '$_base/environment/straight.glb',

    // Scenery — decorative props
    'flag-blue': '$_base/environment/flag-blue.glb',
    'flag-green': '$_base/environment/flag-green.glb',
    'flag-red': '$_base/environment/flag-red.glb',
    'flag-large-blue': '$_base/environment/flag-large-blue.glb',
    'flag-large-green': '$_base/environment/flag-large-green.glb',
    'flag-large-red': '$_base/environment/flag-large-red.glb',
    'ball-blue': '$_base/environment/ball-blue.glb',
    'ball-green': '$_base/environment/ball-green.glb',
    'ball-red': '$_base/environment/ball-red.glb',
    'club-blue': '$_base/environment/club-blue.glb',
    'club-green': '$_base/environment/club-green.glb',
    'club-red': '$_base/environment/club-red.glb',

    // Scenery — trees
    'tree': '$_base/environment/tree.glb',
    'tree-tall': '$_base/environment/tree-tall.glb',
    'tree-autumn': '$_base/environment/tree-autumn.glb',
    'tree-autumn-tall': '$_base/environment/tree-autumn-tall.glb',

    // Scenery — walls & supports
    'wall-left': '$_base/environment/wall-left.glb',
    'wall-right': '$_base/environment/wall-right.glb',
    'support': '$_base/environment/support.glb',
    'support-low': '$_base/environment/support-low.glb',
    'support-bottom': '$_base/environment/support-bottom.glb',
    'support-low-bottom': '$_base/environment/support-low-bottom.glb',
  };

  // --- Mapping game concepts to actual models ---

  /// Vehicle models for the "car" obstacle — picks randomly for variety.
  static const _carModels = [
    'sedan',
    'sedan-sports',
    'hatchback-sports',
    'taxi',
    'police',
    'suv',
    'suv-luxury',
  ];

  /// Large vehicle models for variety.
  static const _truckModels = [
    'van',
    'truck',
    'delivery',
    'ambulance',
  ];

  /// Map obstacle types to one or more model IDs.
  /// When multiple options exist, one is picked randomly per spawn.
  static const _obstacleModelPool = <ObstacleType, List<String>>{
    // Parking lot — real vehicles blocking the path
    ObstacleType.car: _carModels,
    ObstacleType.shoppingCart: ['kart-oobi', 'kart-oodi', 'kart-ooli', 'kart-oopi', 'kart-oozi'],
    ObstacleType.speedBump: ['cone-flat', 'debris-bumper'],
    // Security — checkpoint barriers and scanners
    ObstacleType.barricade: ['cone', 'obstacle-block'],
    ObstacleType.metalDetector: ['structure-gate'],
    ObstacleType.bagCheckStation: ['box', 'delivery-flat'],
    ObstacleType.securityGate: ['structure-gates', 'structure-gate-wide'],
    // Shops — merchandise and food stalls in the walkway
    ObstacleType.merchandiseRack: ['kart-ooli', 'kart-oopi', 'box'],
    ObstacleType.foodCart: ['kart-oobi', 'kart-oodi', 'kart-oozi'],
    ObstacleType.bench: ['obstacle-block'],
    // Ticket booths — queue management obstacles
    ObstacleType.ropeLine: ['cone', 'cone'],
    ObstacleType.turnstile: ['structure-gate', 'obstacle-diamond'],
    ObstacleType.ticketKiosk: ['box', 'structure-gate-building'],
  };

  /// NPC walker character pool (all characters except the player's 'e').
  static const _walkerModels = [
    'character-a',
    'character-b',
    'character-c',
    'character-d',
    'character-f',
    'character-g',
    'character-h',
    'character-i',
    'character-j',
    'character-k',
    'character-l',
    'character-m',
    'character-n',
    'character-o',
    'character-p',
    'character-q',
    'character-r',
  ];

  /// Security guard models (subset with darker/uniform look).
  static const _securityModels = [
    'character-a',
    'character-b',
    'character-c',
  ];

  /// Get the player model ID.
  static String get playerModelId => 'character-e';

  /// Pick a random model ID for an obstacle type.
  static String obstacleModelId(ObstacleType type) {
    final pool = _obstacleModelPool[type];
    if (pool == null || pool.isEmpty) return 'box';
    return pool[_random.nextInt(pool.length)];
  }

  /// Pick a random NPC model ID.
  static String npcModelId(NpcType type) {
    if (type == NpcType.stationary) {
      return _securityModels[_random.nextInt(_securityModels.length)];
    }
    return _walkerModels[_random.nextInt(_walkerModels.length)];
  }

  /// Preload all models. Failures are logged but don't block the game.
  Future<void> preloadAll() async {
    final futures = <Future<void>>[];
    for (final entry in _modelPaths.entries) {
      futures.add(
        _bridge.loadModel(entry.key, entry.value).catchError((_) {}),
      );
    }
    await Future.wait(futures);
  }

  /// Preload only essential models for faster initial load.
  Future<void> preloadEssential() async {
    final essential = [
      'character-e', // player
      'sedan',
      'taxi',
      'box',
      'cone',
      'character-a',
      'character-f',
    ];
    final futures = essential
        .where((id) => _modelPaths.containsKey(id))
        .map((id) => _bridge.loadModel(id, _modelPaths[id]!).catchError((_) {}))
        .toList();
    await Future.wait(futures);
  }
}
