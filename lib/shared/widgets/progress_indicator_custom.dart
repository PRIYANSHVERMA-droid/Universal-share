import 'package:flutter/material.dart';
import '../../core/constants/theme_constants.dart';

class GradientProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final List<Color>? gradient;

  const GradientProgressBar({
    super.key,
    required this.value,
    this.height = 8.0,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);
    final activeGradient = gradient ?? ThemeConstants.primaryGradient;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              if (progress > 0)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: constraints.maxWidth * progress,
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: activeGradient),
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: activeGradient.first.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
