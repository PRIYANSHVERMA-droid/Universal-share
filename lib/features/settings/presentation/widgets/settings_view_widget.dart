import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/universal_share_logo.dart';
import '../../application/settings_providers.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../core/theme/app_typography.dart';

class SettingsViewWidget extends ConsumerWidget {
  const SettingsViewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final deviceName = ref.watch(deviceNameProvider);
    final downloadPath = ref.watch(downloadPathProvider);
    final autoAccept = ref.watch(autoAcceptProvider);
    final trustedDevices = ref.watch(trustedDevicesListProvider);

    final nameController = TextEditingController(text: deviceName);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: AppTypography.headingLarge(Colors.white),
            ),
            const SizedBox(height: 20),

            // 1. Device Profile Settings
            Text(
              "Device Configuration",
              style: AppTypography.headingSmall(isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Device Display Name",
                    style: AppTypography.bodySmall(isDark ? Colors.white60 : Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Enter device name",
                      hintStyle: const TextStyle(color: Colors.white38),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
                        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                      ),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        ref.read(deviceNameProvider.notifier).update(val.trim());
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Transfer Configuration
            Text(
              "Transfer Preferences",
              style: AppTypography.headingSmall(isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                children: [
                  // Download Path Picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Download Folder Location",
                              style: AppTypography.bodyMedium(isDark ? Colors.white : Colors.black),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              downloadPath,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall(isDark ? Colors.white60 : Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.folder_open_rounded, color: Color(0xFF00F2FE)),
                        onPressed: () async {
                          final path = await FilePicker.platform.getDirectoryPath();
                          if (path != null) {
                            ref.read(downloadPathProvider.notifier).update(path);
                          }
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Colors.white10),
                  
                  // Auto-accept toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "Auto-accept from Trusted Devices",
                      style: AppTypography.bodyMedium(isDark ? Colors.white : Colors.black),
                    ),
                    subtitle: Text(
                      "Skip PIN code verification for known paired devices",
                      style: AppTypography.bodySmall(isDark ? Colors.white60 : Colors.black54),
                    ),
                    value: autoAccept,
                    activeTrackColor: ThemeConstants.successColor,
                    onChanged: (val) {
                      ref.read(autoAcceptProvider.notifier).update(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Trusted Devices List
            Text(
              "Trusted / Paired Devices",
              style: AppTypography.headingSmall(isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 12),
            trustedDevices.isEmpty
                ? _buildNoTrustedDevices(context)
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: trustedDevices.length,
                    itemBuilder: (context, index) {
                      final device = trustedDevices[index];
                      final shortFingerprint = device.fingerprint.length > 20
                          ? "${device.fingerprint.substring(0, 8)}...${device.fingerprint.substring(device.fingerprint.length - 8)}"
                          : device.fingerprint;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              UniversalShareLogo(platform: device.platform, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device.name,
                                      style: AppTypography.bodyLarge(isDark ? Colors.white : Colors.black),
                                    ),
                                    Text(
                                      "SHA256: $shortFingerprint",
                                      style: AppTypography.bodySmall(isDark ? Colors.white38 : Colors.black45),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.link_off_rounded, color: ThemeConstants.errorColor),
                                tooltip: "Revoke Trust",
                                onPressed: () {
                                  ref.read(trustedDevicesListProvider.notifier).removeDevice(device.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTrustedDevices(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.verified_user_outlined,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 44,
            ),
            const SizedBox(height: 8),
            Text(
              "No Trusted Devices Yet",
              style: AppTypography.bodyMedium(isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(height: 2),
            Text(
              "Pair with a device using a PIN code to add it here.",
              style: AppTypography.bodySmall(isDark ? Colors.white30 : Colors.black38),
            ),
          ],
        ),
      ),
    );
  }
}
