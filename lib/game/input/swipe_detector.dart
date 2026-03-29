import 'package:flutter/gestures.dart';

enum SwipeDirection { left, right, up, down }

typedef SwipeCallback = void Function(SwipeDirection direction);

/// Detects swipe gestures from raw pointer events.
class SwipeDetector {
  final SwipeCallback onSwipe;
  final double minSwipeDistance;

  Offset? _startPosition;

  SwipeDetector({
    required this.onSwipe,
    this.minSwipeDistance = 30.0,
  });

  void onPanStart(DragStartDetails details) {
    _startPosition = details.globalPosition;
  }

  void onPanEnd(DragEndDetails details) {
    // Use velocity for more responsive swipe detection
    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.distance > 100) {
      if (velocity.dx.abs() > velocity.dy.abs()) {
        onSwipe(velocity.dx > 0 ? SwipeDirection.right : SwipeDirection.left);
      } else {
        onSwipe(velocity.dy < 0 ? SwipeDirection.up : SwipeDirection.down);
      }
    }
    _startPosition = null;
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (_startPosition == null) return;
    final delta = details.globalPosition - _startPosition!;
    if (delta.distance < minSwipeDistance) return;

    if (delta.dx.abs() > delta.dy.abs()) {
      onSwipe(delta.dx > 0 ? SwipeDirection.right : SwipeDirection.left);
    } else {
      onSwipe(delta.dy < 0 ? SwipeDirection.up : SwipeDirection.down);
    }
    // Reset to prevent repeat triggers from same gesture
    _startPosition = details.globalPosition;
  }
}
