import 'package:flutter/material.dart';
import '../../../../core/models/device_model.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/platform_icon.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../core/theme/app_typography.dart';

class DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Platform Icon with visual border
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              ),
            ),
            child: PlatformIcon(
              platform: device.platform,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Device details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device.name,
                      style: AppTypography.headingSmall(
                        isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    if (device.isTrusted) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        color: ThemeConstants.successColor,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 4),
                Text(
                  "${device.ip}:${device.port}",
                  style: AppTypography.bodySmall(
                    isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Pulsing status dot
          Row(
            children: [
              Text(
                "Tap to Send",
                style: AppTypography.bodySmall(
                  isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(width: 8),
              const _PulsingStatusDot(),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingStatusDot extends StatefulWidget {
  const _PulsingStatusDot();

  @override
  State<_PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<_PulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ThemeConstants.successColor.withOpacity(0.4 + (_controller.value * 0.6)),
            boxShadow: [
              BoxShadow(
                color: ThemeConstants.successColor.withOpacity(0.2 + (_controller.value * 0.6)),
                blurRadius: 6 * _controller.value,
                spreadRadius: 2 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
