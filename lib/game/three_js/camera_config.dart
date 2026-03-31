import 'dart:math';

import '../../config/game_config.dart';

/// Translates the game's pseudo-3D perspective parameters into three.js
/// PerspectiveCamera configuration.
class CameraConfig {
  // Camera positioned behind and above the player, looking down the road.
  static const double cameraY = 10.0;
  static const double cameraZ = GameConfig.playerWorldZ - 12; // = -2

  // Look ahead of the player down the road
  static const double lookAtX = 0;
  static const double lookAtY = 0.0;
  static const double lookAtZ = GameConfig.playerWorldZ + 60; // = 70

  static const double nearPlane = 1.0;
  static const double farPlane = 250.0;

  /// Compute vertical FOV that adapts to aspect ratio.
  /// On wide screens (desktop), use ~60°. On tall/narrow screens (mobile
  /// portrait), widen the FOV so the player stays visible.
  static double computeFov(double screenWidth, double screenHeight) {
    final aspect = screenWidth / screenHeight;
    if (aspect >= 1.0) {
      // Landscape / desktop — standard FOV
      return 60.0;
    }
    // Portrait — increase FOV as the screen gets narrower.
    // At aspect 0.5 (very tall phone) → ~80°, at 0.75 → ~70°.
    return 60.0 + (1.0 - aspect) * 40.0;
  }

  /// Build the camera parameters map for [ThreeBridge.syncScene].
  /// Adjusts camera height and look-at for portrait aspect ratios
  /// so the player character stays comfortably in view.
  static Map<String, double> buildCameraUpdate(
      double screenWidth, double screenHeight) {
    final aspect = screenWidth / screenHeight;
    // In portrait, lower the camera slightly and look further ahead
    // so the player sits in the lower-third rather than the bottom edge.
    final yAdjust = aspect < 1.0 ? (1.0 - aspect) * 3.0 : 0.0;
    final lookZAdjust = aspect < 1.0 ? (1.0 - aspect) * 20.0 : 0.0;

    return {
      'fov': computeFov(screenWidth, screenHeight),
      'near': nearPlane,
      'far': farPlane,
      'posX': 0,
      'posY': cameraY - yAdjust,
      'posZ': cameraZ,
      'lookX': lookAtX,
      'lookY': lookAtY,
      'lookZ': lookAtZ + lookZAdjust,
    };
  }
}
