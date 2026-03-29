import '../config/game_config.dart';

enum GameStatus { playing, gameOver, won, paused }

class WorldState {
  double distanceTraveled = 0;
  int score = 0;
  int lives = GameConfig.startingLives;
  double currentSpeed = GameConfig.baseSpeed;
  bool isInvulnerable = false;
  double invulnerabilityTimer = 0;
  GameStatus status = GameStatus.playing;

  /// Speed multiplier from zone.
  double zoneSpeedMultiplier = 1.0;

  /// Whether player is on a reverse walkway.
  bool onReverseWalkway = false;

  void update(double dt) {
    if (status != GameStatus.playing) return;

    final effectiveSpeed = currentSpeed * zoneSpeedMultiplier;
    distanceTraveled += effectiveSpeed * dt;
    score = distanceTraveled.toInt();

    if (isInvulnerable) {
      invulnerabilityTimer -= dt;
      if (invulnerabilityTimer <= 0) {
        isInvulnerable = false;
        invulnerabilityTimer = 0;
      }
    }

    // Check win condition
    if (distanceTraveled >= GameConfig.parkEntranceDistance) {
      status = GameStatus.won;
    }
  }

  void onHit() {
    if (isInvulnerable) return;
    lives--;
    isInvulnerable = true;
    invulnerabilityTimer = GameConfig.invulnerabilityDuration;
    if (lives <= 0) {
      status = GameStatus.gameOver;
    }
  }

  void reset() {
    distanceTraveled = 0;
    score = 0;
    lives = GameConfig.startingLives;
    currentSpeed = GameConfig.baseSpeed;
    isInvulnerable = false;
    invulnerabilityTimer = 0;
    status = GameStatus.playing;
    zoneSpeedMultiplier = 1.0;
    onReverseWalkway = false;
  }
}
