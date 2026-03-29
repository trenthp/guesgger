import 'dart:ui';

import '../obstacles/obstacle_data.dart';

enum ZoneType {
  parkingLot,
  walkway,
  security,
  shops,
  ticketBooths,
  parkEntrance,
}

class Zone {
  final ZoneType type;
  final String name;
  final double startDistance;
  final double endDistance;
  final double speedMultiplier;
  final Color groundColor;
  final Color roadColor;
  final List<ObstacleData> obstaclePool;
  final bool isWalkway;
  final bool reversesDirection;
  final double spawnIntervalMin;
  final double spawnIntervalMax;

  const Zone({
    required this.type,
    required this.name,
    required this.startDistance,
    required this.endDistance,
    required this.speedMultiplier,
    required this.groundColor,
    required this.roadColor,
    required this.obstaclePool,
    this.isWalkway = false,
    this.reversesDirection = false,
    this.spawnIntervalMin = 0.8,
    this.spawnIntervalMax = 1.6,
  });

  double get length => endDistance - startDistance;

  bool containsDistance(double distance) {
    return distance >= startDistance && distance < endDistance;
  }
}
