import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/theme_constants.dart';

class RadarAnimation extends StatefulWidget {
  final bool isScanning;
  final double radius;

  const RadarAnimation({
    super.key,
    required this.isScanning,
    this.radius = 120.0,
  });

  @override
  State<RadarAnimation> createState() => _RadarAnimationState();
}

class _RadarAnimationState extends State<RadarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.isScanning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(RadarAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isScanning && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.white.withOpacity(0.01) : Colors.black.withOpacity(0.01),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _RadarPainter(
              animationValue: _controller.value,
              isScanning: widget.isScanning,
              primaryColor: ThemeConstants.primaryGradient.first,
            ),
            child: child,
          );
        },
        child: Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: ThemeConstants.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.primaryGradient.first.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.wifi_tethering_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double animationValue;
  final bool isScanning;
  final Color primaryColor;

  _RadarPainter({
    required this.animationValue,
    required this.isScanning,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw static concentric rings
    for (int i = 1; i <= 3; i++) {
      paint.color = primaryColor.withOpacity(0.04 + (i * 0.02));
      canvas.drawCircle(center, maxRadius * (i / 3), paint);
    }

    if (!isScanning) return;

    // Draw pulsing rings
    final pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 3; i++) {
      final t = (animationValue + i / 3) % 1.0;
      final radius = maxRadius * t;
      pulsePaint.color = primaryColor.withOpacity((1.0 - t) * 0.4);
      canvas.drawCircle(center, radius, pulsePaint);
    }

    // Draw rotating sweep gradient
    final sweepPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          primaryColor.withOpacity(0.0),
          primaryColor.withOpacity(0.12),
          primaryColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.4, 1.0],
        transform: GradientRotation(animationValue * 2 * pi),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isScanning != isScanning;
  }
}
