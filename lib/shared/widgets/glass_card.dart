import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/theme_constants.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final List<Color>? gradient;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient ??
              (isDark
                  ? [
                      Colors.white.withOpacity(0.07),
                      Colors.white.withOpacity(0.02),
                    ]
                  : [
                      Colors.white.withOpacity(0.85),
                      Colors.white.withOpacity(0.45),
                    ]),
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(ThemeConstants.borderRadiusMedium),
        border: Border.all(
          color: isDark
              ? ThemeConstants.darkGlassBorderColor.withOpacity(0.6)
              : ThemeConstants.lightGlassBorderColor,
          width: 1.5,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(ThemeConstants.borderRadiusMedium),
        child: cardContent,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(ThemeConstants.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(ThemeConstants.borderRadiusMedium),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: ThemeConstants.glassBlurX,
            sigmaY: ThemeConstants.glassBlurY,
          ),
          child: cardContent,
        ),
      ),
    );
  }
}
