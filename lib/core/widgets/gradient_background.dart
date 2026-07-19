import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Soft ambient background with blurred colour blobs. Sits behind glass cards
/// to give the app its premium depth. Put page content on top via [child].
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : AppColors.background,
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: _Blob(
            color: AppColors.primary.withValues(alpha: isDark ? 0.30 : 0.22),
            size: 300,
          ),
        ),
        Positioned(
          bottom: -140,
          left: -100,
          child: _Blob(
            color: AppColors.accent.withValues(alpha: isDark ? 0.16 : 0.16),
            size: 320,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
