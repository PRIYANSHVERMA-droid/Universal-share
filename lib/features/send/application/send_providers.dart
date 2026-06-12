import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/device_model.dart';
import '../../../core/models/transfer_session_model.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../core/network/transfer_client.dart';

/// Holds the list of files selected for the next transfer
final selectedFilesProvider = StateProvider<List<File>>((ref) => []);

/// Listens to real-time progress updates of the active sending session
final sendSessionUpdatesProvider = StreamProvider<TransferSessionModel?>((ref) {
  final client = ref.watch(transferClientProvider);
  return client.sessionUpdates.map((session) => session);
});

class SendController extends StateNotifier<AsyncValue<void>> {
  final TransferClient _transferClient;
  final SettingsRepository _settingsRepository;

  SendController(this._transferClient, this._settingsRepository)
      : super(const AsyncValue.data(null));

  /// Initiate transfer request and start uploading files to target device
  Future<void> send({
    required DeviceModel targetDevice,
    required List<File> files,
  }) async {
    state = const AsyncValue.loading();
    try {
      final localId = _settingsRepository.getDeviceId();
      final localName = _settingsRepository.getDeviceName();

      await _transferClient.sendFiles(
        peerIp: targetDevice.ip,
        peerPort: targetDevice.port,
        peerId: targetDevice.id,
        peerName: targetDevice.name,
        peerPlatform: targetDevice.platform,
        peerFingerprint: targetDevice.certFingerprint,
        localDeviceId: localId,
        localDeviceName: localName,
        filesToSend: files,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Request transfer cancellation
  void cancel() {
    _transferClient.cancelSession();
  }
}

final sendControllerProvider =
    StateNotifierProvider<SendController, AsyncValue<void>>((ref) {
  final client = ref.watch(transferClientProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  return SendController(client, settings);
});
