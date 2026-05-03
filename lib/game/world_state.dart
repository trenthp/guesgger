import '../config/game_config.dart';

enum GameStatus { playing, gameOver, won, paused }

class WorldState {
  double distanceTraveled = 0;
  int score = 0;
  double currentSpeed = GameConfig.baseSpeed;
  bool isInvulnerable = false;
  double invulnerabilityTimer = 0;
  bool isStunned = false;
  double stunTimer = 0;
  GameStatus status = GameStatus.playing;

  /// Effective speed multiplier this frame — combines zone speed with
  /// per-lane walkway modifier. Set by [ThreeJsGame] before [update].
  double effectiveSpeedMultiplier = 1.0;

  /// Seconds remaining before the park closes. When 0, the player loses.
  double timeRemaining = GameConfig.parkCloseTime;

  /// True if the player is on a walkway zone (any lane). Used by HUD/visuals.
  bool onWalkway = false;

  void update(double dt) {
    if (status != GameStatus.playing) return;

    if (!isStunned) {
      distanceTraveled += currentSpeed * effectiveSpeedMultiplier * dt;
      score = distanceTraveled.toInt();
    }

    if (isStunned) {
      stunTimer -= dt;
      if (stunTimer <= 0) {
        isStunned = false;
        stunTimer = 0;
      }
    }

    if (isInvulnerable) {
      invulnerabilityTimer -= dt;
      if (invulnerabilityTimer <= 0) {
        isInvulnerable = false;
        invulnerabilityTimer = 0;
      }
    }

    // Park-closing countdown — runs even while stunned.
    timeRemaining -= dt;
    if (timeRemaining <= 0) {
      timeRemaining = 0;
      status = GameStatus.gameOver;
      return;
    }

    if (distanceTraveled >= GameConfig.parkEntranceDistance) {
      status = GameStatus.won;
    }
  }

  void onHit() {
    if (isInvulnerable) return;
    isStunned = true;
    stunTimer = GameConfig.stunDuration;
    isInvulnerable = true;
    invulnerabilityTimer = GameConfig.invulnerabilityDuration;
  }

  void reset() {
    distanceTraveled = 0;
    score = 0;
    currentSpeed = GameConfig.baseSpeed;
    isInvulnerable = false;
    invulnerabilityTimer = 0;
    isStunned = false;
    stunTimer = 0;
    status = GameStatus.playing;
    effectiveSpeedMultiplier = 1.0;
    timeRemaining = GameConfig.parkCloseTime;
    onWalkway = false;
  }
}
