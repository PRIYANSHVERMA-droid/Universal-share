import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/device_model.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../core/network/discovery_service.dart';
import '../../../core/network/transfer_server.dart';

/// Exposes the live list of discovered peers on the network.
final discoveredDevicesProvider = StreamProvider<List<DeviceModel>>((ref) {
  final discoveryService = ref.watch(discoveryServiceProvider);
  return discoveryService.peersStream;
});

/// Controller to start and stop discovery scanning (and the underlying HTTP server).
class DiscoveryController extends StateNotifier<bool> {
  final DiscoveryService _discoveryService;
  final SettingsRepository _settingsRepository;
  final TransferServer _transferServer;

  DiscoveryController(
    this._discoveryService,
    this._settingsRepository,
    this._transferServer,
  ) : super(false);

  /// Spin up the local HTTP server and register the device on mDNS + UDP broadcast.
  Future<void> start() async {
    if (state) return;

    try {
      // 1. Start transfer server first to bind to a port
      final port = await _transferServer.start();

      // 2. Fetch device identity from settings
      final deviceId = _settingsRepository.getDeviceId();
      final deviceName = _settingsRepository.getDeviceName();

      // 3. Publish and browse on the local network
      await _discoveryService.startDiscovery(
        deviceId: deviceId,
        deviceName: deviceName,
        serverPort: port,
      );

      state = true;
    } catch (_) {
      // Ensure clean state if anything binds incorrectly
      await stop();
      rethrow;
    }
  }

  /// Unregister from discovery and close the local transfer server.
  Future<void> stop() async {
    if (!state) return;
    await _discoveryService.stopDiscovery();
    await _transferServer.stop();
    state = false;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

final discoveryControllerProvider =
    StateNotifierProvider<DiscoveryController, bool>((ref) {
  final discovery = ref.watch(discoveryServiceProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  final server = ref.watch(transferServerProvider);
  return DiscoveryController(discovery, settings, server);
});
