import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/device_model.dart';
import '../../../core/utils/file_size_formatter.dart';
import '../../../shared/widgets/universal_share_logo.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_typography.dart';

class SendConfirmationSheet extends ConsumerWidget {
  final DeviceModel targetDevice;
  final List<File> files;

  const SendConfirmationSheet({
    super.key,
    required this.targetDevice,
    required this.files,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate total size
    final int totalSize = files.fold(0, (sum, file) {
      try {
        return sum + file.lengthSync();
      } catch (_) {
        return sum;
      }
    });

    final totalSizeStr = FileSizeFormatter.format(totalSize);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ThemeConstants.darkBgColor : ThemeConstants.lightBgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(ThemeConstants.borderRadiusLarge),
          topRight: Radius.circular(ThemeConstants.borderRadiusLarge),
        ),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              UniversalShareLogo(platform: targetDevice.platform, size: 36),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Send to ${targetDevice.name}",
                  style: AppTypography.headingMedium(isDark ? Colors.white : Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Files list
          Text(
            "Selected files (${files.length} items, $totalSizeStr):",
            style: AppTypography.bodyMedium(isDark ? Colors.white70 : Colors.black87),
          ),
          const SizedBox(height: 8),
          
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: files.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final file = files[index];
                final name = file.path.split(Platform.pathSeparator).last;
                int size = 0;
                try {
                  size = file.lengthSync();
                } catch (_) {}

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall(isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      Text(
                        FileSizeFormatter.format(size),
                        style: AppTypography.bodySmall(isDark ? Colors.white30 : Colors.black45),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
                    ),
                  ),
                  child: Text(
                    "Cancel",
                    style: AppTypography.button(isDark ? Colors.white : Colors.black),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  width: double.infinity,
                  text: "Send",
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
