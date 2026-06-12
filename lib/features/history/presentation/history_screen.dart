import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/file_size_formatter.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/platform_icon.dart';
import '../application/history_providers.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/transfer_file_model.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final history = ref.watch(historyListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Transfer History",
          style: AppTypography.headingMedium(isDark ? Colors.white : Colors.black),
        ),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: ThemeConstants.errorColor),
              tooltip: "Clear All History",
              onPressed: () {
                _showClearConfirmation(context, ref);
              },
            ),
        ],
      ),
      body: history.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              itemCount: history.length,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              itemBuilder: (context, index) {
                final entry = history[index];
                final dateStr = "${entry.timestamp.day}/${entry.timestamp.month}/${entry.timestamp.year} ${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}";
                final sizeStr = FileSizeFormatter.format(entry.totalSize);

                final isSuccess = entry.status == TransferStatus.completed;
                final isCancelled = entry.status == TransferStatus.cancelled;

                Color statusColor = ThemeConstants.successColor;
                IconData statusIcon = Icons.arrow_downward_rounded;
                
                if (entry.isOutgoing) {
                  statusIcon = Icons.arrow_upward_rounded;
                }

                if (!isSuccess) {
                  statusColor = isCancelled ? Colors.grey : ThemeConstants.errorColor;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Direction indicator with background
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            statusIcon,
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Main Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyLarge(isDark ? Colors.white : Colors.black),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  PlatformIcon(platform: entry.peerPlatform, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${entry.isOutgoing ? 'To' : 'From'} ${entry.peerName}",
                                    style: AppTypography.bodySmall(isDark ? Colors.white60 : Colors.black54),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "•  $dateStr",
                                    style: AppTypography.bodySmall(isDark ? Colors.white38 : Colors.black45),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Status & Size
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              sizeStr,
                              style: AppTypography.headingSmall(isDark ? Colors.white70 : Colors.black87),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entry.status.name.toUpperCase(),
                              style: AppTypography.bodySmall(statusColor).copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              "No Transfers Yet",
              style: AppTypography.headingSmall(isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              "Your sent and received files will be logged here.",
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(isDark ? Colors.white30 : Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Clear History"),
          content: const Text("Are you sure you want to clear your entire transfer log? Files on disk will NOT be deleted."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                ref.read(historyListProvider.notifier).clearAll();
                Navigator.of(context).pop();
              },
              child: const Text("Clear", style: TextStyle(color: ThemeConstants.errorColor)),
            ),
          ],
        );
      },
    );
  }
}
