import 'package:flutter/material.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/theme/app_typography.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color>? gradient;
  final bool isLoading;
  final double? width;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient,
    this.isLoading = false,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final activeGradient = gradient ?? ThemeConstants.primaryGradient;
    final isEnabled = onPressed != null && !isLoading;

    return Container(
      width: width ?? double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: isEnabled ? LinearGradient(colors: activeGradient) : null,
        color: isEnabled ? null : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: activeGradient.first.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: AppTypography.button(Colors.white),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
