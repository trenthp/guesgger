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

  /// Compute vertical FOV (~60° gives a tighter, more focused view).
  static double computeFov(double screenWidth, double screenHeight) {
    // Use a fixed FOV that feels good for a runner game
    return 60.0;
  }

  /// Build the camera parameters map for [ThreeBridge.syncScene].
  static Map<String, double> buildCameraUpdate(
      double screenWidth, double screenHeight) {
    return {
      'fov': computeFov(screenWidth, screenHeight),
      'near': nearPlane,
      'far': farPlane,
      'posX': 0,
      'posY': cameraY,
      'posZ': cameraZ,
      'lookX': lookAtX,
      'lookY': lookAtY,
      'lookZ': lookAtZ,
    };
  }
}
