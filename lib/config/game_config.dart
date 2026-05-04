/// All tunable game constants in one place.
class GameConfig {
  // Player
  static const double playerWorldZ = 10.0;
  static const double laneWidth = 3.0;
  static const double jumpDuration = 0.55;
  static const double jumpHeight = 2.5;
  static const double laneSwitchDuration = 0.15;
  static const double invulnerabilityDuration = 2.0;
  static const double stunDuration = 0.8;

  // Camera / Perspective
  static const double focalLengthFactor = 0.55;
  static const double cameraHeight = 12.0;
  static const double nearPlane = 2.0;
  static const double farPlane = 200.0;
  static const double horizonRatio = 0.18;

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

  // Speed — slowed overall for a less frantic, race-against-closing-time feel.
  static const double baseSpeed = 18.0;

  // Walkway lane speed multipliers (split walkway: right with you, left against).
  static const double walkwayLaneMultiplierRight = 1.6;
  static const double walkwayLaneMultiplierMiddle = 1.0;
  static const double walkwayLaneMultiplierLeft = 0.5;

  // Park-closing timer (seconds). Game ends in failure if this hits 0
  // before the player reaches the park entrance.
  static const double parkCloseTime = 120.0;

  // After the world fully transitions to dusk, the park stays dark for this
  // many seconds before closing — gives the player a "park is closing now,
  // hurry" beat instead of cutting straight from daylight to game over.
  static const double parkDarkPhaseDuration = 25.0;

  // Spawn intervals (seconds) - min and max per zone
  static const double spawnIntervalMax = 1.8;
  static const double spawnIntervalMin = 0.6;

  // 3D model asset base paths
  static const String modelBasePath = 'assets/models';
  static const String playerModelPath = '$modelBasePath/player/player.glb';
  static const String obstacleModelPath = '$modelBasePath/obstacles';
  static const String npcModelPath = '$modelBasePath/npcs';
  static const String environmentModelPath = '$modelBasePath/environment';
}
