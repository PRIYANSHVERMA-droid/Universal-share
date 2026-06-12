import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/models/device_model.dart';
import '../../../../shared/widgets/platform_icon.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../core/theme/app_typography.dart';

class ConcentricRadarView extends StatefulWidget {
  final List<DeviceModel> devices;
  final Function(DeviceModel) onDeviceTap;
  final bool isScanning;

  const ConcentricRadarView({
    super.key,
    required this.devices,
    required this.onDeviceTap,
    required this.isScanning,
  });

  @override
  State<ConcentricRadarView> createState() => _ConcentricRadarViewState();
}

class _ConcentricRadarViewState extends State<ConcentricRadarView>
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
  void didUpdateWidget(ConcentricRadarView oldWidget) {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final center = Offset(width / 2, height / 2);
        
        // Dynamic radius based on constraints
        final double maxRadius = min(width, height) * 0.45;
        
        // Define fixed orbital angles & distances for up to 4 devices to match the mockup
        final List<double> angles = [
          -135 * pi / 180, // Top Left (MacBook Air)
          -45 * pi / 180,  // Top Right (iPhone 14 Pro)
          135 * pi / 180,  // Bottom Left (John's PC)
          45 * pi / 180,   // Bottom Right (Pixel 7 Pro)
        ];

        final List<double> distanceFactors = [0.85, 0.8, 0.75, 0.82];

        // Map devices to coordinates
        final List<Map<String, dynamic>> positionedDevices = [];
        for (int i = 0; i < widget.devices.length; i++) {
          final device = widget.devices[i];
          final angle = angles[i % angles.length];
          final distance = maxRadius * distanceFactors[i % distanceFactors.length];
          
          final offset = Offset(
            center.dx + distance * cos(angle),
            center.dy + distance * sin(angle),
          );
          
          positionedDevices.add({
            'device': device,
            'offset': offset,
          });
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            // 1. Draw concentric rings and connecting lines
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(width, height),
                  painter: _RadarBackgroundPainter(
                    center: center,
                    maxRadius: maxRadius,
                    deviceOffsets: positionedDevices.map((d) => d['offset'] as Offset).toList(),
                    animationValue: _controller.value,
                    isScanning: widget.isScanning,
                    isDark: isDark,
                  ),
                );
              },
            ),

            // 2. Central Node ("You")
            Positioned(
              left: center.dx - 60,
              top: center.dy - 65,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF131A2D) : Colors.white,
                      border: Border.all(
                        color: const Color(0xFF0078D4),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0078D4).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.desktop_windows_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You",
                    style: AppTypography.headingSmall(isDark ? Colors.white : Colors.black)
                        .copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Windows",
                    style: AppTypography.bodySmall(isDark ? Colors.white60 : Colors.black54)
                        .copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),

            // 3. Orbiting Nodes (Discovered Devices)
            ...positionedDevices.map((d) {
              final device = d['device'] as DeviceModel;
              final offset = d['offset'] as Offset;
              
              // Select colors depending on device/platform to match mock mockup
              Color platformColor = const Color(0xFF00F2FE);
              if (device.platform == 'android') platformColor = const Color(0xFF3DDC84);
              if (device.platform == 'ios') platformColor = const Color(0xFFFF2D55);
              if (device.platform == 'macos') platformColor = const Color(0xFFA2AAAD);

              return Positioned(
                left: offset.dx - 50,
                top: offset.dy - 50,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => widget.onDeviceTap(device),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF131A2D) : Colors.white,
                            border: Border.all(
                              color: platformColor.withOpacity(0.7),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: platformColor.withOpacity(0.25),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: PlatformIcon(
                              platform: device.platform,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          device.name,
                          style: AppTypography.bodyMedium(isDark ? Colors.white : Colors.black)
                              .copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              device.platform,
                              style: AppTypography.bodySmall(isDark ? Colors.white54 : Colors.black45)
                                  .copyWith(fontSize: 9),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: ThemeConstants.successColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _RadarBackgroundPainter extends CustomPainter {
  final Offset center;
  final double maxRadius;
  final List<Offset> deviceOffsets;
  final double animationValue;
  final bool isScanning;
  final bool isDark;

  _RadarBackgroundPainter({
    required this.center,
    required this.maxRadius,
    required this.deviceOffsets,
    required this.animationValue,
    required this.isScanning,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = isDark ? const Color(0xFF1B243B) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw concentric radar lines
    for (int i = 1; i <= 4; i++) {
      final radius = maxRadius * (i / 4);
      canvas.drawCircle(center, radius, linePaint);
    }

    // Draw lines connecting center to orbiting device nodes
    final connectionPaint = Paint()
      ..color = const Color(0xFF0078D4).withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = const Color(0xFF0078D4)
      ..style = PaintingStyle.fill;

    for (final offset in deviceOffsets) {
      // Draw connection line
      canvas.drawLine(center, offset, connectionPaint);
      
      // Draw connection point dot
      canvas.drawCircle(offset, 4.0, dotPaint);
    }

    if (!isScanning) return;

    // Draw rotating sweep line
    final sweepPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          const Color(0xFF0078D4).withOpacity(0.0),
          const Color(0xFF0078D4).withOpacity(0.15),
          const Color(0xFF0078D4).withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(animationValue * 2 * pi),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isScanning != isScanning ||
        oldDelegate.deviceOffsets != deviceOffsets;
  }
}
