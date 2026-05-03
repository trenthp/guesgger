import 'package:flutter/material.dart';

import '../config/game_config.dart';
import '../config/theme.dart';
import '../game/world_state.dart';
import '../game/zones/zone_manager.dart';

class HudOverlay extends StatelessWidget {
  final WorldState worldState;
  final ZoneManager zoneManager;

  const HudOverlay({
    super.key,
    required this.worldState,
    required this.zoneManager,
  });

  @override
  Widget build(BuildContext context) {
    final progress = zoneManager.getProgress(worldState.distanceTraveled);
    final timeLeft = worldState.timeRemaining;
    final timeFraction = (timeLeft / GameConfig.parkCloseTime).clamp(0.0, 1.0);
    final isLowTime = timeLeft <= 30;
    final timeColor = isLowTime ? GameTheme.heartFull : GameTheme.hudText;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top bar
            Row(
              children: [
                _GlassCard(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.straighten_rounded,
                        color: GameTheme.hudAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${worldState.score}m',
                        style: const TextStyle(
                          color: GameTheme.hudText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _GlassCard(
                  accent: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: GameTheme.hudAccent,
                          boxShadow: [
                            BoxShadow(
                              color: GameTheme.hudAccent.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        zoneManager.currentZone.name.toUpperCase(),
                        style: const TextStyle(
                          color: GameTheme.hudText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Park-closing countdown
                _GlassCard(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: timeColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(timeLeft),
                        style: TextStyle(
                          color: timeColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          shadows: isLowTime
                              ? [
                                  Shadow(
                                    color: GameTheme.heartGlow,
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Distance progress bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: GameTheme.progressBarBg,
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [
                        GameTheme.hudAccent,
                        GameTheme.progressBar,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GameTheme.progressBar.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Park-closing timer bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: GameTheme.progressBarBg,
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: timeFraction,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isLowTime
                        ? GameTheme.heartFull
                        : GameTheme.hudAccent,
                    boxShadow: isLowTime
                        ? [
                            BoxShadow(
                              color: GameTheme.heartFull.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(double seconds) {
    final total = seconds.ceil().clamp(0, 9999);
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString()}:${s.toString().padLeft(2, '0')}';
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool accent;

  const _GlassCard({required this.child, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: GameTheme.hudBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent ? GameTheme.hudAccent.withValues(alpha: 0.2) : GameTheme.hudBorder,
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}
