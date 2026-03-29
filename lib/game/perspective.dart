import 'dart:ui';

/// Projects 3D world coordinates onto 2D screen coordinates
/// using simple perspective division.
class PerspectiveProjection {
  double focalLength;
  double cameraHeight;
  double screenWidth;
  double screenHeight;
  double horizonY;

  PerspectiveProjection({
    required this.screenWidth,
    required this.screenHeight,
    this.cameraHeight = 12.0,
  })  : focalLength = screenHeight * 0.55,
        horizonY = screenHeight * 0.18;

  void resize(Size size) {
    screenWidth = size.width;
    screenHeight = size.height;
    focalLength = screenHeight * 0.55;
    horizonY = screenHeight * 0.18;
  }

  /// Project a world point to screen coordinates.
  /// Returns null if behind the camera.
  ProjectedPoint? project(double worldX, double worldY, double worldZ) {
    if (worldZ <= 0.5) return null;
    final scale = focalLength / worldZ;
    final screenX = (screenWidth / 2) + (worldX * scale);
    final screenY = horizonY + ((cameraHeight - worldY) * scale);
    return ProjectedPoint(screenX, screenY, scale);
  }

  /// Get the scale factor for a given z distance.
  double getScale(double worldZ) {
    if (worldZ <= 0.5) return 0;
    return focalLength / worldZ;
  }

  /// Convert a screen Y coordinate (below horizon) to world Z distance.
  double screenYToWorldZ(double screenY) {
    final dy = screenY - horizonY;
    if (dy <= 0) return double.infinity;
    return (cameraHeight * focalLength) / dy;
  }

  /// Get road half-width at a given screen Y.
  double getRoadHalfWidthAtScreenY(double screenY, double roadWorldWidth) {
    final z = screenYToWorldZ(screenY);
    if (z == double.infinity) return 0;
    final scale = focalLength / z;
    return (roadWorldWidth / 2) * scale;
  }
}

class ProjectedPoint {
  final double x;
  final double y;
  final double scale;

  const ProjectedPoint(this.x, this.y, this.scale);
}
