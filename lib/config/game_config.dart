/// All tunable game constants in one place.
class GameConfig {
  // Player
  static const int startingLives = 3;
  static const double playerWorldZ = 10.0;
  static const double laneWidth = 3.0;
  static const double jumpDuration = 0.55;
  static const double jumpHeight = 2.5;
  static const double laneSwitchDuration = 0.15;
  static const double invulnerabilityDuration = 2.0;

  // Camera / Perspective
  static const double focalLengthFactor = 0.55; // multiplied by screen height
  static const double cameraHeight = 12.0;
  static const double nearPlane = 2.0;
  static const double farPlane = 200.0;
  static const double horizonRatio = 0.18; // horizon at 18% from top

  // Obstacles
  static const double spawnDistance = 180.0;
  static const double collisionThreshold = 2.5;
  static const double obstacleBaseSize = 2.0;

  // Zone distances (cumulative)
  static const double parkingLotEnd = 500;
  static const double walkway1End = 700;
  static const double securityEnd = 1200;
  static const double walkway2End = 1400;
  static const double shopsEnd = 2000;
  static const double walkway3End = 2200;
  static const double ticketBoothsEnd = 2800;
  static const double walkway4End = 3000;
  static const double parkEntranceDistance = 3000;

  // Speed
  static const double baseSpeed = 30.0; // world units per second
  static const double walkwaySpeedMultiplier = 1.5;

  // Spawn intervals (seconds) - min and max per zone
  static const double spawnIntervalMax = 1.8;
  static const double spawnIntervalMin = 0.6;
}
