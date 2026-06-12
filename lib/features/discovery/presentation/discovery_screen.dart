import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/models/device_model.dart';
import '../../../core/models/transfer_file_model.dart';
import '../../../core/models/transfer_session_model.dart';
import '../../../core/utils/permission_helper.dart';
import '../../history/presentation/widgets/history_view_widget.dart';
import '../../receive/presentation/incoming_request_dialog.dart';
import '../../send/application/send_providers.dart';
import '../../send/presentation/send_confirmation_sheet.dart';
import '../../send/presentation/transfer_progress_screen.dart';
import '../../settings/presentation/widgets/settings_view_widget.dart';
import '../../settings/application/settings_providers.dart';
import '../application/discovery_providers.dart';
import '../../receive/application/receive_providers.dart';
import 'widgets/mini_radar_scanner.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/universal_share_logo.dart';
import '../../../core/network/update_service.dart';
import 'package:url_launcher/url_launcher.dart';


// Navigation tab state provider
final selectedTabProvider = StateProvider<int>((ref) => 0);

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  // No mock/demo devices — only show discovered devices

  @override
  void initState() {
    super.initState();
    // Request permissions on Android
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionHelper.requestDiscoveryPermissions();
      PermissionHelper.requestStoragePermission();
      // Start discovery server automatically for visibility
      ref.read(discoveryControllerProvider.notifier).start();
      // Silent update check on startup
      _checkUpdatesSilently();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;
    
    // Riverpod states
    final selectedTab = ref.watch(selectedTabProvider);
    final isScanning = ref.watch(discoveryControllerProvider);
    final peersAsync = ref.watch(discoveredDevicesProvider);

    // Watch incoming sessions and progress (Real transfers)
    _listenToRealTransferStreams(context, ref);

    // No demo sessions — continue to show discovery UI

    return Scaffold(
      backgroundColor: const Color(0xFF070A13),
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: selectedTab,
              onTap: (index) => ref.read(selectedTabProvider.notifier).state = index,
              backgroundColor: const Color(0xFF0D1221),
              selectedItemColor: const Color(0xFF00F2FE),
              unselectedItemColor: Colors.white30,
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.wifi_tethering_rounded), label: 'Nearby'),
                BottomNavigationBarItem(icon: Icon(Icons.send_rounded), label: 'Send'),
                BottomNavigationBarItem(icon: Icon(Icons.download_rounded), label: 'Receive'),
                BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
                BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
              ],
            )
          : null,
      body: isDesktop
          ? Row(
              children: [
                // Desktop Sidebar
                _buildSidebar(context, selectedTab),
                // Main Panel Content
                Expanded(
                  child: Container(
                    color: const Color(0xFF070A13),
                    child: _buildTabContent(context, selectedTab, isScanning, peersAsync, isDesktop),
                  ),
                ),
              ],
            )
          : SafeArea(
              child: _buildTabContent(context, selectedTab, isScanning, peersAsync, isDesktop),
            ),
    );
  }

  // ===========================================================================
  // SIDEBAR (Desktop)
  // ===========================================================================
  // ===========================================================================
  // SIDEBAR (Desktop)
  // ===========================================================================
  Widget _buildSidebar(BuildContext context, int activeTab) {
    final deviceName = ref.watch(deviceNameProvider);
    
    String myPlatform = 'Unknown';
    if (Platform.isWindows) {
      myPlatform = 'Windows';
    } else if (Platform.isMacOS) {
      myPlatform = 'macOS';
    } else if (Platform.isLinux) {
      myPlatform = 'Linux';
    } else if (Platform.isAndroid) {
      myPlatform = 'Android';
    } else if (Platform.isIOS) {
      myPlatform = 'iOS';
    }

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1221),
        border: Border(
          right: BorderSide(
            color: Color(0xFF1E2842),
            width: 1.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding Header
          Row(
            children: [
              const UniversalShareLogo(size: 38),
              const SizedBox(width: 12),
              Text(
                'Universal Share',
                style: AppTypography.headingMedium(Colors.white).copyWith(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Navigation list
          _buildSidebarItem(0, 'Nearby', Icons.wifi_tethering_rounded, activeTab),
          _buildSidebarItem(1, 'Send', Icons.send_rounded, activeTab),
          _buildSidebarItem(2, 'Receive', Icons.download_rounded, activeTab),
          _buildSidebarItem(3, 'History', Icons.history_rounded, activeTab),
          _buildSidebarItem(4, 'Settings', Icons.settings_rounded, activeTab),
          
          const Spacer(),

          // My Device Panel Card (mockup replica)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161D30),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF232D47),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UniversalShareLogo(
                      size: 24,
                      platform: Platform.operatingSystem,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Device',
                            style: AppTypography.bodySmall(Colors.white54).copyWith(fontSize: 9),
                          ),
                          Text(
                            deviceName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium(Colors.white)
                                .copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Trusted',
                        style: TextStyle(color: Color(0xFF00E676), fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16, color: Colors.white10),
                // OS & Connection details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.window_rounded, color: Colors.white30, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          myPlatform,
                          style: AppTypography.bodySmall(Colors.white30).copyWith(fontSize: 9),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.wifi_rounded, color: Colors.white30, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'My Wi-Fi Network',
                          style: AppTypography.bodySmall(Colors.white30).copyWith(fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, String label, IconData icon, int activeTab) {
    final isSelected = activeTab == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => ref.read(selectedTabProvider.notifier).state = index,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1B243B) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF00F2FE) : Colors.white30,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: AppTypography.bodyMedium(isSelected ? Colors.white : Colors.white30)
                      .copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TABS CONTROLLERS
  // ===========================================================================
  Widget _buildTabContent(
    BuildContext context,
    int index,
    bool isScanning,
    AsyncValue<List<DeviceModel>> peersAsync,
    bool isDesktop,
  ) {
    switch (index) {
      case 0:
        return _buildNearbyTab(context, isScanning, peersAsync, isDesktop);
      case 1:
        return _buildSendTab(context, peersAsync);
      case 2:
        return _buildReceiveTab(context);
      case 3:
        return const HistoryViewWidget();
      case 4:
        return const SettingsViewWidget();
      default:
        return const Center(child: Text("Not found"));
    }
  }

  // ===========================================================================
  // NEARBY SCANNING RADAR TAB
  // ===========================================================================
  Widget _buildNearbyTab(
    BuildContext context,
    bool isScanning,
    AsyncValue<List<DeviceModel>> peersAsync,
    bool isDesktop,
  ) {
    // Show only discovered peers (exclude local 'self')
    final displayDevices = peersAsync.value?.where((p) => p.id != 'self').toList() ?? [];
    final trustedDevicesList = ref.watch(trustedDevicesListProvider);

    // Sync isTrusted dynamically with the trusted devices list
    final updatedDevices = displayDevices.map((device) {
      final isTrusted = trustedDevicesList.any((d) => d.id == device.id);
      return device.copyWith(isTrusted: isTrusted);
    }).toList();

    if (!isDesktop) {
      // Mobile Layout
      return Scaffold(
        backgroundColor: const Color(0xFF070A13),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _handleMobileFabTap(context, updatedDevices),
          backgroundColor: Colors.transparent,
          elevation: 8,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF0078D4), Color(0xFF7000FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0078D4).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row matching mockup
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nearby Devices',
                          style: AppTypography.headingLarge(Colors.white).copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _triggerRefresh,
                          child: RichText(
                            text: TextSpan(
                              text: 'Looking for devices on ',
                              style: AppTypography.bodySmall(Colors.white30).copyWith(fontSize: 11),
                              children: const [
                                TextSpan(
                                  text: 'My Wi-Fi Network',
                                  style: TextStyle(
                                    color: Color(0xFF00F2FE),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  MiniRadarScanner(isScanning: isScanning, size: 64),
                ],
              ),
              const SizedBox(height: 24),

              // Device Cards list
              Expanded(
                child: updatedDevices.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: updatedDevices.length,
                        itemBuilder: (ctx, idx) => _buildDeviceCard(context, updatedDevices[idx]),
                      ),
              ),

              // Troubleshoot Link
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextButton(
                    onPressed: () => _showTroubleshootDialog(context),
                    child: Text(
                      "Can't see the device you're looking for? Troubleshoot",
                      style: AppTypography.bodySmall(const Color(0xFF00F2FE)).copyWith(fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Desktop Layout
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nearby Devices',
                    style: AppTypography.headingLarge(Colors.white),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _triggerRefresh,
                    child: RichText(
                      text: TextSpan(
                        text: 'Looking for devices on ',
                        style: AppTypography.bodySmall(Colors.white30).copyWith(fontSize: 12),
                        children: const [
                          TextSpan(
                            text: 'My Wi-Fi Network',
                            style: TextStyle(
                              color: Color(0xFF00F2FE),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _triggerRefresh,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 14),
                    label: Text(
                      'Refresh',
                      style: AppTypography.button(Colors.white70).copyWith(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1E2842)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  MiniRadarScanner(isScanning: isScanning, size: 76),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Central Area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: updatedDevices.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: updatedDevices.length,
                          itemBuilder: (ctx, idx) => _buildDeviceCard(context, updatedDevices[idx]),
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _showTroubleshootDialog(context),
                  child: Text(
                    "Can't see the device you're looking for? Troubleshoot",
                    style: AppTypography.bodySmall(const Color(0xFF00F2FE)).copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bottom Feature Highlights (UI Highlights from mockup)
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  context,
                  title: 'No Internet',
                  subtitle: 'Required',
                  icon: Icons.wifi_off_rounded,
                  color: const Color(0xFF0078D4),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard(
                  context,
                  title: 'No Limits',
                  subtitle: 'File Size',
                  icon: Icons.all_inclusive_rounded,
                  color: const Color(0xFF00E676),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard(
                  context,
                  title: 'Cross Platform',
                  subtitle: 'All Devices',
                  icon: Icons.devices_rounded,
                  color: const Color(0xFF7000FF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard(
                  context,
                  title: '100% Private',
                  subtitle: 'No Servers',
                  icon: Icons.lock_outline_rounded,
                  color: const Color(0xFFFFA000),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1221),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E2842),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.headingSmall(Colors.white).copyWith(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall(Colors.white30).copyWith(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_tethering_rounded, color: Colors.white12, size: 48),
          const SizedBox(height: 16),
          Text(
            'Looking for nearby devices...',
            style: AppTypography.bodyMedium(Colors.white30),
          ),
          Text(
            'Make sure other devices have Universal Share open.',
            style: AppTypography.bodySmall(Colors.white24),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, DeviceModel device) {
    final isTrusted = device.isTrusted;
    
    String platformLabel = device.platform.toUpperCase();

    final platformLower = device.platform.toLowerCase();
    if (platformLower == 'android') {
      platformLabel = 'Android Device';
    } else if (platformLower == 'ios') {
      platformLabel = 'iOS Device';
    } else if (platformLower == 'macos') {
      platformLabel = 'macOS Device';
    } else if (platformLower == 'windows') {
      platformLabel = 'Windows Device';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1221),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E2842),
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleSendFilesToDevice(context, device),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              UniversalShareLogo(
                size: 40,
                platform: device.platform,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: AppTypography.headingSmall(Colors.white).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      platformLabel,
                      style: AppTypography.bodySmall(Colors.white30).copyWith(
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isTrusted 
                      ? const Color(0xFF00E676).withOpacity(0.12)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isTrusted 
                        ? const Color(0xFF00E676).withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  isTrusted ? 'Trusted' : 'Not Trusted',
                  style: TextStyle(
                    color: isTrusted ? const Color(0xFF00E676) : Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white24,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SEND TAB
  // ===========================================================================
  Widget _buildSendTab(BuildContext context, AsyncValue<List<DeviceModel>> peersAsync) {
    final displayDevices = peersAsync.value?.where((p) => p.id != 'self').toList() ?? [];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send Files',
            style: AppTypography.headingLarge(Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a device to start transferring files securely.',
            style: AppTypography.bodySmall(Colors.white54),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: displayDevices.isEmpty
                ? Center(
                    child: Text(
                      'No nearby devices found',
                      style: AppTypography.bodyMedium(Colors.white30),
                    ),
                  )
                : ListView.builder(
                    itemCount: displayDevices.length,
                    itemBuilder: (context, index) {
                      final device = displayDevices[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1221),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF1E2842),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            UniversalShareLogo(
                              size: 40,
                              platform: device.platform,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.name,
                                    style: AppTypography.headingSmall(Colors.white).copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "${device.platform.toUpperCase()} • ${device.ip}",
                                    style: AppTypography.bodySmall(Colors.white30).copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _handleSendFilesToDevice(context, device),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0078D4),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text('Select'),
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
  }

  // ===========================================================================
  // RECEIVE TAB
  // ===========================================================================
  Widget _buildReceiveTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.downloading_rounded,
            color: Color(0xFF00F2FE),
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            "Waiting for Incoming Files...",
            style: AppTypography.headingMedium(Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            "Other devices can search and send files to you securely over the Wi-Fi.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  void _triggerRefresh() {
    ref.read(discoveryControllerProvider.notifier).stop();
    Future.delayed(const Duration(milliseconds: 300), () {
      ref.read(discoveryControllerProvider.notifier).start();
    });
  }

  void _showTroubleshootDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Troubleshooting Tips'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Ensure both devices are connected to the same Wi-Fi network.'),
            SizedBox(height: 8),
            Text('2. Make sure Universal Share is running and in scanning mode on the other device.'),
            SizedBox(height: 8),
            Text('3. Turn off any active VPN or Firewall settings.'),
            SizedBox(height: 8),
            Text('4. Verify that local network access/discovery permissions are allowed.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendFilesToDevice(BuildContext context, DeviceModel device) async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result == null || result.paths.isEmpty) return;

      final files = result.paths.whereType<String>().map((p) => File(p)).toList();
      if (!context.mounted) return;

      // Show confirmation sheet
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => SendConfirmationSheet(
          targetDevice: device,
          files: files,
        ),
      );

      if (confirmed == true && context.mounted) {
        await ref.read(sendControllerProvider.notifier).send(
          targetDevice: device,
          files: files,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting files: $e')),
      );
    }
  }

  Future<void> _handleMobileFabTap(BuildContext context, List<DeviceModel> displayDevices) async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result == null || result.paths.isEmpty) return;

      final files = result.paths.whereType<String>().map((p) => File(p)).toList();
      if (!context.mounted) return;

      // Show device selection bottom sheet
      final targetDevice = await showModalBottomSheet<DeviceModel>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => DeviceSelectionSheet(
          devices: displayDevices,
          onDeviceSelected: (dev) => Navigator.of(ctx).pop(dev),
        ),
      );

      if (targetDevice == null) return;
      if (!context.mounted) return;

      // Show confirmation sheet
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => SendConfirmationSheet(
          targetDevice: targetDevice,
          files: files,
        ),
      );

      if (confirmed == true && context.mounted) {
        await ref.read(sendControllerProvider.notifier).send(
          targetDevice: targetDevice,
          files: files,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting files: $e')),
      );
    }
  }

  // ===========================================================================
  // REAL TRANSFER STREAM TRIGGERS
  // ===========================================================================
  void _listenToRealTransferStreams(BuildContext context, WidgetRef ref) {
    // Listen for incoming transfer requests
    ref.listen<AsyncValue<TransferSessionModel>>(incomingSessionRequestsProvider, (prev, next) {
      next.whenData((session) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => IncomingRequestDialog(session: session),
        );
      });
    });

    // Listen for incoming progress state to push receiving progress screen
    ref.listen<AsyncValue<TransferSessionModel?>>(receiveSessionUpdatesProvider, (prev, next) {
      final currentSession = next.value;
      final prevSession = prev?.value;

      if (currentSession != null &&
          currentSession.status == TransferStatus.transferring &&
          (prevSession == null || prevSession.status == TransferStatus.pending)) {
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const TransferProgressScreen(isOutgoing: false),
          ),
        );
      }
    });

    // Listen for outgoing (send) progress state to push sending progress screen
    ref.listen<AsyncValue<TransferSessionModel?>>(sendSessionUpdatesProvider, (prev, next) {
      final currentSession = next.value;
      final prevSession = prev?.value;

      if (currentSession != null &&
          currentSession.status == TransferStatus.transferring &&
          (prevSession == null || prevSession.status == TransferStatus.pending)) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const TransferProgressScreen(isOutgoing: true),
          ),
        );
      }
    });
  }

  Future<void> _checkUpdatesSilently() async {
    try {
      final updateService = ref.read(updateServiceProvider);
      final updateInfo = await updateService.checkForUpdates();
      if (updateInfo.hasUpdate && mounted) {
        _showUpdateDialog(context, updateInfo);
      }
    } catch (_) {}
  }

  void _showUpdateDialog(BuildContext context, AppUpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1221),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E2842), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.system_update_rounded, color: Color(0xFF00F2FE), size: 28),
            SizedBox(width: 12),
            Text(
              'Update Available!',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version (${updateInfo.latestVersion}) of Universal Share is available.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Changelog:',
              style: TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              width: double.maxFinite,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: SingleChildScrollView(
                child: Text(
                  updateInfo.changelog,
                  style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.4),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final uri = Uri.parse(updateInfo.downloadUrl ?? updateInfo.releaseUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0078D4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SUPPORTING PRIVATE WIDGETS
// =============================================================================

class DeviceSelectionSheet extends StatelessWidget {
  final List<DeviceModel> devices;
  final Function(DeviceModel) onDeviceSelected;

  const DeviceSelectionSheet({
    super.key,
    required this.devices,
    required this.onDeviceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1221),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text(
            'Select Device to Send',
            style: AppTypography.headingMedium(Colors.white),
          ),
          const SizedBox(height: 16),
          if (devices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No nearby devices found',
                  style: AppTypography.bodyMedium(Colors.white30),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: devices.length,
                itemBuilder: (ctx, index) {
                  final device = devices[index];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: UniversalShareLogo(
                      size: 32,
                      platform: device.platform,
                    ),
                    title: Text(device.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(device.platform.toUpperCase(), style: const TextStyle(color: Colors.white30, fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white30),
                    onTap: () {
                      onDeviceSelected(device);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
