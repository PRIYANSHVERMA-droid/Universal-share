import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/cert_manager.dart';
import '../network/discovery_service.dart';
import '../network/transfer_client.dart';
import '../network/transfer_server.dart';
import '../storage/history_repository.dart';
import '../storage/settings_repository.dart';
import '../storage/trusted_devices_repository.dart';

// 1. Storage & Config Providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError("sharedPreferencesProvider must be overridden in main.dart");
});

final certManagerProvider = Provider<CertManager>((ref) {
  return CertManager();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsRepository(prefs);
});

final trustedDevicesRepositoryProvider = Provider<TrustedDevicesRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TrustedDevicesRepository(prefs);
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

// 2. Networking Providers
final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  return DiscoveryService();
});

final transferServerProvider = Provider<TransferServer>((ref) {
  final cert = ref.watch(certManagerProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  final trust = ref.watch(trustedDevicesRepositoryProvider);
  final history = ref.watch(historyRepositoryProvider);
  return TransferServer(cert, settings, trust, history);
});

final transferClientProvider = Provider<TransferClient>((ref) {
  final cert = ref.watch(certManagerProvider);
  final history = ref.watch(historyRepositoryProvider);
  return TransferClient(cert, history);
});
