import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/device_model.dart';
import '../application/send_providers.dart';
import 'send_confirmation_sheet.dart';

class SendFilesDialog extends StatefulWidget {
  final DeviceModel targetDevice;
  final VoidCallback onCancel;

  const SendFilesDialog({
    super.key,
    required this.targetDevice,
    required this.onCancel,
  });

  @override
  State<SendFilesDialog> createState() => _SendFilesDialogState();
}

class _SendFilesDialogState extends State<SendFilesDialog> {
  // Mock files selection list
  final List<Map<String, dynamic>> _files = [
    {
      'name': 'Vacation Photos',
      'size': '1.25 GB',
      'icon': Icons.folder_rounded,
      'color': Colors.amber,
      'checked': true,
    },
    {
      'name': 'Project Proposal.pdf',
      'size': '28.5 MB',
      'icon': Icons.picture_as_pdf_rounded,
      'color': Colors.redAccent,
      'checked': true,
    },
    {
      'name': 'Video.mp4',
      'size': '1.18 GB',
      'icon': Icons.video_file_rounded,
      'color': Colors.purpleAccent,
      'checked': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Calculate count and size
    int selectedCount = _files.where((f) => f['checked'] == true).length;
    String totalSize = selectedCount == 3
        ? '2.45 GB'
        : selectedCount == 2
            ? '1.27 GB'
            : selectedCount == 1
                ? _files.firstWhere((f) => f['checked'] == true)['size']
                : '0 B';

    return Container(
      width: 320,
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
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                onPressed: widget.onCancel,
              ),
              Text(
                'Send Files',
                style: AppTypography.headingSmall(Colors.white).copyWith(fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                onPressed: widget.onCancel,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total Files info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$selectedCount files selected',
                style: AppTypography.bodySmall(const Color(0xFF00F2FE))
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                totalSize,
                style: AppTypography.bodySmall(Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Files listing
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161D30),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF232D47),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (file['color'] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          file['icon'] as IconData,
                          color: file['color'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file['name'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium(Colors.white)
                                  .copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              file['size'] as String,
                              style: AppTypography.bodySmall(Colors.white54)
                                  .copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      Checkbox(
                        value: file['checked'] as bool,
                        onChanged: (val) {
                          setState(() {
                            file['checked'] = val;
                          });
                        },
                        activeColor: const Color(0xFF00F2FE),
                        checkColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(color: Colors.white30),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Select Device / Send Button
          Consumer(
            builder: (context, ref, child) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () async {
                    // Let user pick real files
                    final parentContext = context;
                    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
                    if (result == null || result.paths.isEmpty) return;
                    final files = result.paths.whereType<String>().map((p) => File(p)).toList();

                    if (!mounted) return;

                    // Close Send Dialog now that we're mounted and have files
                    widget.onCancel();

                    // Show confirmation sheet
                    final confirmed = await showModalBottomSheet<bool>(
                      context: parentContext,
                      isScrollControlled: true,
                      builder: (ctx) => SendConfirmationSheet(targetDevice: widget.targetDevice, files: files),
                    );

                    if (confirmed == true) {
                      await ref.read(sendControllerProvider.notifier).send(
                        targetDevice: widget.targetDevice,
                        files: files,
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0078D4), Color(0xFF7000FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7000FF).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Select Device',
                      style: AppTypography.button(Colors.white)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
