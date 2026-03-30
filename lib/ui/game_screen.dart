import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';
import '../game/input/swipe_detector.dart';
import '../game/three_js_game.dart';
import 'hud.dart';
import 'three_canvas_widget.dart';

class GameScreen extends StatefulWidget {
  final VoidCallback onGameOver;
  final VoidCallback onWin;
  final void Function(int score, String zoneName) onGameOverWithInfo;
  final void Function(int score) onWinWithInfo;

  const GameScreen({
    super.key,
    required this.onGameOver,
    required this.onWin,
    required this.onGameOverWithInfo,
    required this.onWinWithInfo,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late ThreeJsGame _game;
  late SwipeDetector _swipeDetector;
  late AnimationController _hintFade;
  bool _sceneReady = false;

  @override
  void initState() {
    super.initState();
    _game = ThreeJsGame();

    _game.onGameOver = () {
      widget.onGameOverWithInfo(
        _game.worldState.score,
        _game.zoneManager.currentZone.name,
      );
    };
    _game.onWin = () {
      widget.onWinWithInfo(_game.worldState.score);
    };
    _game.onStateChanged = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    };

    // Initialize game logic (model preloading starts in background)
    _game.initialize(this);

    _swipeDetector = SwipeDetector(
      onSwipe: (direction) {
        switch (direction) {
          case SwipeDirection.left:
            _game.moveLeft();
            break;
          case SwipeDirection.right:
            _game.moveRight();
            break;
          case SwipeDirection.up:
            _game.jump();
            break;
          case SwipeDirection.down:
            break;
        }
      },
    );

    _hintFade = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  void _onSceneReady() {
    if (!mounted) return;
    setState(() => _sceneReady = true);

    // Get screen size and start the game loop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      _game.start(size.width, size.height);
      _game.attachTicker(this);
    });
  }

  @override
  void dispose() {
    _hintFade.dispose();
    _game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) => _game.onKeyEvent(event),
        child: GestureDetector(
          onPanStart: _swipeDetector.onPanStart,
          onPanUpdate: _swipeDetector.onPanUpdate,
          onPanEnd: _swipeDetector.onPanEnd,
          child: Stack(
            children: [
              // three.js 3D canvas
              ThreeCanvasWidget(onReady: _onSceneReady),

              // HUD overlay
              if (_sceneReady && _game.isInitialized)
                HudOverlay(
                  worldState: _game.worldState,
                  zoneManager: _game.zoneManager,
                ),

              // Fading swipe hint
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                    CurvedAnimation(
                      parent: _hintFade,
                      curve: const Interval(0.5, 1.0),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swipe_rounded,
                            color: GameTheme.hudAccent.withValues(alpha: 0.5),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Swipe or use Arrow Keys / WASD',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
