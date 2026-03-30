import 'dart:math';

import 'package:flutter/animation.dart';

import '../../config/game_config.dart';

/// Pure-Dart player state and physics — no rendering, no Flame dependency.
///
/// Extracted from the original [Player] Flame Component. Handles lane
/// switching, jump arc, invulnerability flash, and stun state.
class PlayerState {
  int currentLane = 0; // -1, 0, 1
  int _targetLane = 0;
  double _laneTransition = 0;
  double _worldX = 0;

  bool isJumping = false;
  double _jumpTimer = 0;
  double _jumpHeight = 0;

  bool isInvulnerable = false;
  bool isStunned = false;
  double _flashTimer = 0;
  double _runTimer = 0;

  double get worldX => _worldX;
  double get jumpHeight => _jumpHeight;
  double get runTimer => _runTimer;
  double get flashTimer => _flashTimer;

  /// Current animation state name for the 3D model.
  /// Maps to Kenney character-pack animation names.
  String get animationState {
    if (isStunned) return 'die';
    if (isJumping) return 'pick-up';
    return 'sprint';
  }

  /// Whether the player should be visible this frame (handles flash).
  bool get isVisibleThisFrame {
    if (isInvulnerable && !isStunned) {
      return sin(_flashTimer * pi) <= 0.5;
    }
    return true;
  }

  void moveLane(int direction) {
    final newLane = (currentLane + direction).clamp(-1, 1);
    if (newLane != currentLane) {
      _targetLane = newLane;
      _laneTransition = 0;
    }
  }

  void jump() {
    if (!isJumping) {
      isJumping = true;
      _jumpTimer = 0;
    }
  }

  void update(double dt) {
    _runTimer += dt;

    // Lane switching interpolation
    if (currentLane != _targetLane) {
      _laneTransition += dt / GameConfig.laneSwitchDuration;
      if (_laneTransition >= 1.0) {
        _laneTransition = 0;
        currentLane = _targetLane;
      }
    }

    // Calculate world X from lane
    final currentX = currentLane * GameConfig.laneWidth;
    final targetX = _targetLane * GameConfig.laneWidth;
    if (currentLane != _targetLane) {
      final t = Curves.easeOut.transform(_laneTransition.clamp(0.0, 1.0));
      _worldX = currentX + (targetX - currentX) * t;
    } else {
      _worldX = currentX;
    }

    // Jump animation
    if (isJumping) {
      _jumpTimer += dt;
      final t = _jumpTimer / GameConfig.jumpDuration;
      if (t >= 1.0) {
        isJumping = false;
        _jumpTimer = 0;
        _jumpHeight = 0;
      } else {
        _jumpHeight = sin(t * pi) * GameConfig.jumpHeight;
      }
    }

    // Flash timer for invulnerability
    if (isInvulnerable) {
      _flashTimer += dt * 8;
    } else {
      _flashTimer = 0;
    }
  }

  void reset() {
    currentLane = 0;
    _targetLane = 0;
    _laneTransition = 0;
    _worldX = 0;
    isJumping = false;
    _jumpTimer = 0;
    _jumpHeight = 0;
    isInvulnerable = false;
    isStunned = false;
    _flashTimer = 0;
    _runTimer = 0;
  }
}
