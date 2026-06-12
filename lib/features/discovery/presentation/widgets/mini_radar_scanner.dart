import 'dart:math';
import 'package:flutter/material.dart';

class MiniRadarScanner extends StatefulWidget {
  final bool isScanning;
  final double size;

  const MiniRadarScanner({
    super.key,
    required this.isScanning,
    this.size = 80.0,
  });

  @override
  State<MiniRadarScanner> createState() => _MiniRadarScannerState();
}

class _MiniRadarScannerState extends State<MiniRadarScanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.isScanning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(MiniRadarScanner oldWidget) {
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
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0D1221),
        border: Border.all(
          color: const Color(0xFF1E2842),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F2FE).withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _MiniRadarPainter(
              animationValue: _controller.value,
              isScanning: widget.isScanning,
            ),
          );
        },
      ),
    );
  }
}

class _MiniRadarPainter extends CustomPainter {
  final double animationValue;
  final bool isScanning;

  _MiniRadarPainter({
    required this.animationValue,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 4;

    final linePaint = Paint()
      ..color = const Color(0xFF1E2842).withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 1. Draw concentric circles
    for (int i = 1; i <= 3; i++) {
      final r = maxRadius * (i / 3);
      canvas.drawCircle(center, r, linePaint);
    }

    // 2. Draw crosshairs lines
    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      linePaint,
    );

    // 3. Draw a glowing center dot
    final centerDotPaint = Paint()
      ..color = const Color(0xFF00F2FE)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.5, centerDotPaint);
    
    final centerDotGlow = Paint()
      ..color = const Color(0xFF00F2FE).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 7.0, centerDotGlow);

    if (!isScanning) return;

    // 4. Draw rotating sweep gradient
    final sweepPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          const Color(0xFF00F2FE).withOpacity(0.0),
          const Color(0xFF00F2FE).withOpacity(0.18),
          const Color(0xFF00F2FE).withOpacity(0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
        transform: GradientRotation(animationValue * 2 * pi),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniRadarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isScanning != isScanning;
  }
}
