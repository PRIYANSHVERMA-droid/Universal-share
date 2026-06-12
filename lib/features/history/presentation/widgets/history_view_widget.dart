import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../../../shared/widgets/platform_icon.dart';
import '../../application/history_providers.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/models/transfer_file_model.dart';

class HistoryViewWidget extends StatefulWidget {
  const HistoryViewWidget({super.key});

  @override
  State<HistoryViewWidget> createState() => _HistoryViewWidgetState();
}

class _HistoryViewWidgetState extends State<HistoryViewWidget> {
  String _activeTab = 'All';

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final history = ref.watch(historyListProvider);
        
        // Filter history depending on active tab
        final filteredHistory = history.where((entry) {
          if (_activeTab == 'Sent') return entry.isOutgoing;
          if (_activeTab == 'Received') return !entry.isOutgoing;
          return true;
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'History',
                    style: AppTypography.headingLarge(Colors.white),
                  ),
                  if (history.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_sweep_rounded, color: ThemeConstants.errorColor, size: 18),
                      label: const Text('Clear All', style: TextStyle(color: ThemeConstants.errorColor, fontSize: 13)),
                      onPressed: () {
                        ref.read(historyListProvider.notifier).clearAll();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Segmented Tab Buttons (All, Sent, Received)
              Row(
                children: ['All', 'Sent', 'Received'].map((tabName) {
                  final isSelected = _activeTab == tabName;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeTab = tabName;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0078D4) : const Color(0xFF161D30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF00F2FE) : const Color(0xFF232D47),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            tabName,
                            style: AppTypography.bodySmall(isSelected ? Colors.white : Colors.white70)
                                .copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // History list
              Expanded(
                child: filteredHistory.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        itemCount: filteredHistory.length,
                        itemBuilder: (context, index) {
                          final entry = filteredHistory[index];
                          final sizeStr = FileSizeFormatter.format(entry.totalSize);
                          
                          // Format timestamp to match mockup (e.g. Today, 9:41 AM)
                          final now = DateTime.now();
                          String dateStr;
                          if (entry.timestamp.year == now.year &&
                              entry.timestamp.month == now.month &&
                              entry.timestamp.day == now.day) {
                            final hour = entry.timestamp.hour > 12 ? entry.timestamp.hour - 12 : entry.timestamp.hour;
                            final ampm = entry.timestamp.hour >= 12 ? 'PM' : 'AM';
                            final min = entry.timestamp.minute.toString().padLeft(2, '0');
                            dateStr = 'Today, $hour:$min $ampm';
                          } else {
                            final hour = entry.timestamp.hour > 12 ? entry.timestamp.hour - 12 : entry.timestamp.hour;
                            final ampm = entry.timestamp.hour >= 12 ? 'PM' : 'AM';
                            final min = entry.timestamp.minute.toString().padLeft(2, '0');
                            dateStr = 'Yesterday, $hour:$min $ampm';
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E1424),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF1B243B),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Icon with platform details
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF161D30),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF2E384E),
                                      width: 1,
                                    ),
                                  ),
                                  child: PlatformIcon(
                                    platform: entry.peerPlatform,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // File transfers and target device
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.isOutgoing 
                                            ? "To ${entry.peerName}" 
                                            : "From ${entry.peerName}",
                                        style: AppTypography.headingSmall(Colors.white).copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        "${entry.fileName} • $sizeStr",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodySmall(Colors.white54).copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),

                                // Timestamp & StatusBadge
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      dateStr,
                                      style: AppTypography.bodySmall(Colors.white30).copyWith(fontSize: 10),
                                    ),
                                    const SizedBox(height: 6),
                                    // Status Pills
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: entry.status == TransferStatus.completed
                                            ? const Color(0xFF00E676).withOpacity(0.12)
                                            : entry.status == TransferStatus.cancelled
                                                ? Colors.white.withOpacity(0.08)
                                                : ThemeConstants.errorColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        entry.status == TransferStatus.completed
                                            ? 'Completed'
                                            : entry.status == TransferStatus.cancelled
                                                ? 'Cancelled'
                                                : 'Failed',
                                        style: TextStyle(
                                          color: entry.status == TransferStatus.completed
                                              ? const Color(0xFF00E676)
                                              : entry.status == TransferStatus.cancelled
                                                  ? Colors.white70
                                                  : ThemeConstants.errorColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history_toggle_off_rounded,
            color: Colors.white24,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            "No Transfer History Yet",
            style: AppTypography.bodyMedium(Colors.white60),
          ),
          const SizedBox(height: 4),
          Text(
            "Your completed file transfers will appear here.",
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(Colors.white30),
          ),
        ],
      ),
    );
  }
}
