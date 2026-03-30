import 'package:flutter/material.dart';

import 'ui/game_over_screen.dart';
import 'ui/game_screen.dart';
import 'ui/main_menu_screen.dart';
import 'ui/win_screen.dart';

void main() {
  runApp(const ThemeParkRunnerApp());
}

class ThemeParkRunnerApp extends StatelessWidget {
  const ThemeParkRunnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Theme Park Runner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const AppNavigator(),
    );
  }
}

enum AppPage { menu, game, gameOver, win }

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  AppPage _currentPage = AppPage.menu;
  int _lastScore = 0;
  String _lastZone = '';

  void _goToGame() {
    setState(() => _currentPage = AppPage.game);
  }

  void _goToMenu() {
    setState(() => _currentPage = AppPage.menu);
  }

  void _onGameOver(int score, String zoneName) {
    _lastScore = score;
    _lastZone = zoneName;
    setState(() => _currentPage = AppPage.gameOver);
  }

  void _onWin(int score) {
    _lastScore = score;
    setState(() => _currentPage = AppPage.win);
  }

  Widget _buildPage() {
    switch (_currentPage) {
      case AppPage.menu:
        return MainMenuScreen(key: const ValueKey('menu'), onStart: _goToGame);
      case AppPage.game:
        return GameScreen(
          key: UniqueKey(),
          onGameOver: () {},
          onWin: () {},
          onGameOverWithInfo: _onGameOver,
          onWinWithInfo: _onWin,
        );
      case AppPage.gameOver:
        return GameOverScreen(
          key: const ValueKey('gameOver'),
          score: _lastScore,
          zoneName: _lastZone,
          onRetry: _goToGame,
          onMenu: _goToMenu,
        );
      case AppPage.win:
        return WinScreen(
          key: const ValueKey('win'),
          score: _lastScore,
          onPlayAgain: _goToGame,
          onMenu: _goToMenu,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _buildPage(),
    );
  }
}
