import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/transfer_file_model.dart';
import '../../../core/models/transfer_session_model.dart';
import '../../../core/utils/file_size_formatter.dart';
import '../../../shared/widgets/platform_icon.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_typography.dart';
import '../application/send_providers.dart';
import '../../receive/application/receive_providers.dart';

class TransferProgressScreen extends ConsumerWidget {
  final bool isOutgoing;

  const TransferProgressScreen({
    super.key,
    required this.isOutgoing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch real session updates
    final realSessionAsync = ref.watch(
      isOutgoing ? sendSessionUpdatesProvider : receiveSessionUpdatesProvider,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF070A13),
      body: SafeArea(
        child: realSessionAsync.when(
          data: (session) {
            if (session == null) {
              return const Center(child: Text("No active transfer session", style: TextStyle(color: Colors.white)));
            }
            return _buildProgressContent(context, ref, session);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F2FE)),
            ),
          ),
          error: (err, stack) => Center(
            child: Text(
              "Error: $err",
              style: const TextStyle(color: ThemeConstants.errorColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressContent(
    BuildContext context,
    WidgetRef ref,
    TransferSessionModel session,
  ) {
    final progress = session.progress;
    final totalSizeStr = FileSizeFormatter.format(session.totalSize);
    final transferredSizeStr = FileSizeFormatter.format(session.bytesTransferred);
    final speedStr = FileSizeFormatter.formatSpeed(session.speed);
    
    // Custom formatted remaining time to match mockup (MM:SS)
    String etaStr = '00:00';
    if (session.speed > 0) {
      final remainingBytes = session.totalSize - session.bytesTransferred;
      final remainingSec = (remainingBytes / session.speed).ceil();
      final mins = (remainingSec ~/ 60).toString().padLeft(2, '0');
      final secs = (remainingSec % 60).toString().padLeft(2, '0');
      etaStr = '$mins:$secs';
    }

    // Check terminal states
    final isCompleted = session.status == TransferStatus.completed;
    final isFailed = session.status == TransferStatus.failed;
    final isCancelled = session.status == TransferStatus.cancelled;

    if (isCompleted) {
      return _buildTerminalState(
        context,
        ref,
        title: "Transfer Completed",
        icon: Icons.check_circle_outline_rounded,
        iconColor: ThemeConstants.successColor,
        message: "Successfully transferred ${session.files.length} files.",
      );
    }
    if (isFailed || isCancelled) {
      return _buildTerminalState(
        context,
        ref,
        title: isCancelled ? "Transfer Cancelled" : "Transfer Failed",
        icon: isCancelled ? Icons.cancel_outlined : Icons.error_outline_rounded,
        iconColor: isCancelled ? Colors.grey : ThemeConstants.errorColor,
        message: isCancelled ? "The transfer was aborted by user." : (session.errorMessage ?? "An unexpected error occurred."),
      );
    }

    return Center(
      child: Container(
        width: 350,
        height: 520,
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
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 20),
                Text(
                  'Transfer in Progress',
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
            const SizedBox(height: 24),

            // Orbit circle representation of receiving peer
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF161D30),
                border: Border.all(
                  color: const Color(0xFF00F2FE).withOpacity(0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F2FE).withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: PlatformIcon(
                  platform: session.peerPlatform,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Peer labels
            Text(
              session.isOutgoing 
                  ? "Sending to ${session.peerName}" 
                  : "Receiving from ${session.peerName}",
              style: AppTypography.headingSmall(Colors.white).copyWith(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              session.peerPlatform.toUpperCase(),
              style: AppTypography.bodySmall(Colors.white54).copyWith(fontSize: 10),
            ),
            const SizedBox(height: 24),

            // Stats info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$totalSizeStr • ${session.files.length} files",
                  style: AppTypography.bodySmall(Colors.white54).copyWith(fontSize: 11),
                ),
                Text(
                  "${(progress * 100).toInt()}%",
                  style: AppTypography.bodySmall(const Color(0xFF00F2FE))
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Horizontal Linear Progress bar (custom gradient)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 10,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF1B243B),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: (progress * 1000).toInt(),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF00F2FE), Color(0xFF7000FF)],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: ((1.0 - progress) * 1000).toInt(),
                      child: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "$transferredSizeStr / $totalSizeStr",
                style: AppTypography.bodySmall(Colors.white30).copyWith(fontSize: 10),
              ),
            ),
            const SizedBox(height: 28),

            // Stats Block Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        speedStr,
                        style: AppTypography.headingSmall(Colors.white).copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Speed',
                        style: AppTypography.bodySmall(Colors.white30).copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        etaStr,
                        style: AppTypography.headingSmall(Colors.white).copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Remaining',
                        style: AppTypography.bodySmall(Colors.white30).copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                // Pause button
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.pause_rounded, color: Colors.white, size: 14),
                  label: Text(
                    'Pause',
                    style: AppTypography.button(Colors.white).copyWith(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2E384E)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Cancel Transfer Link
            TextButton(
              onPressed: () {
                if (session.isOutgoing) {
                  ref.read(sendControllerProvider.notifier).cancel();
                } else {
                  ref.read(receiveControllerProvider).decline(session.id);
                }
              },
              child: Text(
                'Cancel Transfer',
                style: AppTypography.button(ThemeConstants.errorColor)
                    .copyWith(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalState(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required String message,
  }) {
    return Center(
      child: Container(
        width: 350,
        height: 520,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: iconColor),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTypography.headingMedium(Colors.white).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(Colors.white70),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF161C2C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF2E384E)),
                ),
              ),
              child: const Text("Done"),
            ),
          ],
        ),
      ),
    );
  }
}
