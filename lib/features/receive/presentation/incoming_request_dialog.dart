import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/transfer_session_model.dart';
import '../../../core/utils/file_size_formatter.dart';
import '../../../core/theme/app_typography.dart';
 
import '../application/receive_providers.dart';

class IncomingRequestDialog extends ConsumerWidget {
  final TransferSessionModel session;

  const IncomingRequestDialog({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSizeStr = FileSizeFormatter.format(session.totalSize);

    // File icons row logic to display
    final List<Map<String, dynamic>> fileIcons = [
      {'icon': Icons.folder_rounded, 'color': Colors.amber},
      {'icon': Icons.image_rounded, 'color': Colors.blue},
      {'icon': Icons.picture_as_pdf_rounded, 'color': Colors.redAccent},
      {'icon': Icons.description_rounded, 'color': const Color(0xFF0078D4)},
    ];

    // Display PIN code
    final pinString = session.pin ?? '7321';
    final pinDigits = pinString.split('');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1221),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF1E2842),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 20),
                Text(
                  'Incoming Request',
                  style: AppTypography.headingSmall(Colors.white).copyWith(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Peer Device Info
            Text(
              "${session.peerName} (${session.peerPlatform})",
              textAlign: TextAlign.center,
              style: AppTypography.headingSmall(Colors.white)
                  .copyWith(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "wants to send you",
              style: AppTypography.bodySmall(Colors.white54),
            ),
            const SizedBox(height: 16),

            // Files Summary
            Text(
              "${session.files.length} files",
              style: AppTypography.headingLarge(Colors.white)
                  .copyWith(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(
              totalSizeStr,
              style: AppTypography.bodySmall(const Color(0xFF00F2FE))
                  .copyWith(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // File Type Icons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...fileIcons.map((item) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: item['color'] as Color,
                      size: 18,
                    ),
                  );
                }),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '+1',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // PIN Code Display
            Text(
              'PIN Code',
              style: AppTypography.bodySmall(Colors.white30).copyWith(fontSize: 10),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: pinDigits.map((digit) {
                return Container(
                  width: 44,
                  height: 52,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161D30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF00F2FE).withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F2FE).withOpacity(0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    digit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Decline & Accept Action Buttons
            Row(
              children: [
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                      onTap: () {
                        ref.read(receiveControllerProvider).decline(session.id);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF161D30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2E384E)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Decline',
                          style: AppTypography.button(Colors.white70).copyWith(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                      onTap: () {
                        ref.read(receiveControllerProvider).accept(session.id);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0078D4), Color(0xFF00F2FE)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F2FE).withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Accept',
                          style: AppTypography.button(Colors.black).copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
