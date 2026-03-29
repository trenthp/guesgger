import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';

/// Manages loading and caching of sprite assets with graceful fallback.
///
/// Drop PNG files into the asset folders and they'll be picked up automatically.
/// If a sprite isn't found, the component falls back to procedural rendering.
/// See assets/ASSET_SPEC.md for the full specification.
class SpriteManager {
  final Map<String, Sprite> _sprites = {};
  final Map<String, List<Sprite>> _sheetFrames = {};
  final Set<String> _failedPaths = {};

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Try to load a single sprite. Returns true if successful.
  Future<bool> _tryLoadSprite(String path) async {
    if (_failedPaths.contains(path)) return false;
    if (_sprites.containsKey(path)) return true;

    try {
      final image = await Flame.images.load(path);
      _sprites[path] = Sprite(image);
      return true;
    } catch (_) {
      _failedPaths.add(path);
      return false;
    }
  }

  /// Try to load a sprite sheet and extract individual frames.
  Future<bool> _tryLoadSheet(
    String path, {
    required int frameCount,
    required double frameWidth,
    required double frameHeight,
  }) async {
    if (_failedPaths.contains(path)) return false;
    if (_sheetFrames.containsKey(path)) return true;

    try {
      final image = await Flame.images.load(path);
      final sheet = SpriteSheet(
        image: image,
        srcSize: Vector2(frameWidth, frameHeight),
      );
      final frames = <Sprite>[];
      for (int i = 0; i < frameCount; i++) {
        frames.add(sheet.getSprite(0, i));
      }
      _sheetFrames[path] = frames;
      return true;
    } catch (_) {
      _failedPaths.add(path);
      return false;
    }
  }

  /// Initialize: try to load all known assets.
  /// Missing files are silently skipped — procedural fallback is used.
  Future<void> initialize() async {
    // --- Obstacles ---
    for (final name in obstacleAssetNames.values) {
      await _tryLoadSprite('obstacles/$name.png');
    }
    await _tryLoadSprite('obstacles/security_gate_blocked.png');

    // --- Player ---
    await _tryLoadSheet(
      'player/run.png',
      frameCount: 6,
      frameWidth: 128,
      frameHeight: 128,
    );
    await _tryLoadSheet(
      'player/jump.png',
      frameCount: 4,
      frameWidth: 128,
      frameHeight: 128,
    );
    await _tryLoadSprite('player/idle.png');
    await _tryLoadSprite('player/hit.png');

    // --- NPCs ---
    await _tryLoadSheet(
      'npcs/walker.png',
      frameCount: 4,
      frameWidth: 96,
      frameHeight: 96,
    );
    await _tryLoadSprite('npcs/security.png');

    // --- Backgrounds (per zone) ---
    for (final zone in ['parking_lot', 'security', 'shops', 'ticket_booths']) {
      for (final layer in ['sky', 'far', 'near']) {
        await _tryLoadSprite('backgrounds/$zone/$layer.png');
      }
    }

    // --- UI ---
    for (final name in ['logo', 'heart_full', 'heart_empty', 'button_bg']) {
      await _tryLoadSprite('ui/$name.png');
    }

    _initialized = true;
  }

  // ------ Public API ------

  /// Get a loaded sprite by path, or null if not available.
  Sprite? getSprite(String path) => _sprites[path];

  /// Check if a sprite was successfully loaded.
  bool hasSprite(String path) => _sprites.containsKey(path);

  /// Get frames from a loaded sprite sheet.
  List<Sprite>? getSheetFrames(String path) => _sheetFrames[path];

  /// Check if a sprite sheet was successfully loaded.
  bool hasSheet(String path) => _sheetFrames.containsKey(path);

  /// Get a specific frame from a sheet based on time and step duration.
  Sprite? getAnimFrame(String path, double time, {double stepTime = 0.1}) {
    final frames = _sheetFrames[path];
    if (frames == null || frames.isEmpty) return null;
    final index = ((time / stepTime) % frames.length).floor();
    return frames[index];
  }

  // --- Obstacle helpers ---

  /// Get the sprite for an obstacle type, or null for procedural fallback.
  Sprite? getObstacleSprite(String typeName) {
    return _sprites['obstacles/$typeName.png'];
  }

  /// Whether a sprite exists for this obstacle type.
  bool hasObstacleSprite(String typeName) {
    return _sprites.containsKey('obstacles/$typeName.png');
  }

  // --- Player helpers ---

  /// Get the current player sprite/frame based on state.
  /// Returns null if no sprite assets are loaded (use procedural fallback).
  Sprite? getPlayerFrame({
    required bool isRunning,
    required bool isJumping,
    required bool isHit,
    required double animTime,
  }) {
    if (isHit && hasSprite('player/hit.png')) {
      return _sprites['player/hit.png'];
    }
    if (isJumping) {
      final frame = getAnimFrame('player/jump.png', animTime, stepTime: 0.14);
      if (frame != null) return frame;
    }
    if (isRunning) {
      final frame = getAnimFrame('player/run.png', animTime, stepTime: 0.1);
      if (frame != null) return frame;
    }
    return _sprites['player/idle.png'];
  }

  bool get hasPlayerSprites =>
      hasSheet('player/run.png') || hasSprite('player/idle.png');

  // --- NPC helpers ---

  Sprite? getNpcFrame({required bool isStationary, required double animTime}) {
    if (isStationary) return _sprites['npcs/security.png'];
    return getAnimFrame('npcs/walker.png', animTime, stepTime: 0.1);
  }

  bool get hasNpcSprites =>
      hasSheet('npcs/walker.png') || hasSprite('npcs/security.png');

  /// Map from ObstacleType enum name to asset file name.
  static const obstacleAssetNames = {
    'car': 'car',
    'shoppingCart': 'shopping_cart',
    'speedBump': 'speed_bump',
    'barricade': 'barricade',
    'metalDetector': 'metal_detector',
    'bagCheckStation': 'bag_check_station',
    'securityGate': 'security_gate',
    'merchandiseRack': 'merchandise_rack',
    'foodCart': 'food_cart',
    'bench': 'bench',
    'ropeLine': 'rope_line',
    'turnstile': 'turnstile',
    'ticketKiosk': 'ticket_kiosk',
  };
}
