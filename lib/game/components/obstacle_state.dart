import '../../config/game_config.dart';
import '../obstacles/obstacle_data.dart';

/// Pure-Dart obstacle state — no rendering, no Flame dependency.
///
/// Tracks an obstacle's position, type, and lane. Used for collision
/// detection and to drive the three.js scene sync.
class ObstacleState {
  final ObstacleData data;
  final int lane; // -1, 0, 1
  double worldZ;

  /// For securityGate: which lane is walled off (-1, 0, or 1).
  final int? blockedLane;

  /// Unique ID for the three.js scene object.
  final String sceneId;

  /// Whether this obstacle has been added to the three.js scene.
  bool addedToScene = false;

  ObstacleState({
    required this.data,
    required this.lane,
    required this.worldZ,
    required this.sceneId,
    this.blockedLane,
  });

  double get worldX => lane * GameConfig.laneWidth;

  bool get isPastCamera => worldZ < GameConfig.nearPlane;

  void advance(double distance) {
    worldZ -= distance;
  }
}
