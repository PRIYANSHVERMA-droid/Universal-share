import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:universal_share/core/network/cert_manager.dart';
import 'package:universal_share/core/network/network_utils.dart';
import 'package:universal_share/core/network/transfer_server.dart';
import 'package:universal_share/core/network/transfer_client.dart';
import 'package:universal_share/core/storage/settings_repository.dart';
import 'package:universal_share/core/storage/trusted_devices_repository.dart';
import 'package:universal_share/core/storage/history_repository.dart';
import 'package:universal_share/core/models/transfer_session_model.dart';
import 'package:universal_share/core/models/transfer_file_model.dart';

class MockPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;
  MockPathProvider(this.tempPath);

  @override
  Future<String?> getApplicationSupportPath() async => tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;

  @override
  Future<String?> getDownloadsPath() async => tempPath;
}

void main() {
  late Directory tempDir;
  late MockPathProvider mockPathProvider;
  late SharedPreferences prefs;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = null;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('universal_share_test');
    mockPathProvider = MockPathProvider(tempDir.path);
    PathProviderPlatform.instance = mockPathProvider;

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('NetworkUtils Tests', () {
    test('getBroadcastAddress calculation', () {
      final ip = '192.168.1.15';
      final mask = '255.255.255.0';
      final broadcast = NetworkUtils.getBroadcastAddress(ip, mask);
      expect(broadcast, '192.168.1.255');
    });

    test('isSameSubnet validation', () {
      final mask = '255.255.255.0';
      expect(NetworkUtils.isSameSubnet('192.168.1.15', '192.168.1.50', mask), true);
      expect(NetworkUtils.isSameSubnet('192.168.1.15', '192.168.2.15', mask), false);
    });
  });

  group('CertManager Tests', () {
    test('Initialization generates certificates and fingerprint', () async {
      final certManager = CertManager();
      await certManager.init();

      expect(certManager.certPem, isNotEmpty);
      expect(certManager.keyPem, isNotEmpty);
      expect(certManager.fingerprint, isNotEmpty);
      expect(certManager.fingerprint.contains(':'), true);

      final context = certManager.getSecurityContext();
      expect(context, isNotNull);
    });
  });

  group('TLS Transfer Server/Client Integration Loopback Test', () {
    test('Full file transfer flow', () async {
      // 1. Initialize repositories
      final settingsRepo = SettingsRepository(prefs);
      final trustedDevicesRepo = TrustedDevicesRepository(prefs);
      final historyRepo = HistoryRepository();
      await historyRepo.init();

      // Get/Set local device info
      final localId = settingsRepo.getDeviceId();
      final localName = settingsRepo.getDeviceName();

      // 2. Initialize CertManager
      final certManager = CertManager();
      await certManager.init();

      // 3. Initialize & Start TransferServer
      final transferServer = TransferServer(
        certManager,
        settingsRepo,
        trustedDevicesRepo,
        historyRepo,
      );

      final port = await transferServer.start();
      expect(port, isPositive);

      // 4. Create dummy file to send
      final srcFile = File('${tempDir.path}/test_send.txt');
      await srcFile.writeAsString('Hello, this is a local loopback TLS file transfer test!');

      final transferClient = TransferClient(certManager, historyRepo);

      // Listen for incoming requests on server and auto-accept
      final serverUpdates = <TransferSessionModel>[];
      final incomingSessionSubscription = transferServer.incomingSessions.listen((session) {
        serverUpdates.add(session);
        // Accept the session
        transferServer.acceptSession(session.id);
      });

      // 5. Trigger client transfer
      final clientUpdates = <TransferSessionModel>[];
      final clientUpdatesSubscription = transferClient.sessionUpdates.listen((session) {
        clientUpdates.add(session);
      });

      await transferClient.sendFiles(
        peerIp: '127.0.0.1',
        peerPort: port,
        peerId: localId,
        peerName: localName,
        peerPlatform: 'windows',
        peerFingerprint: certManager.fingerprint,
        localDeviceId: localId,
        localDeviceName: localName,
        filesToSend: [srcFile],
      );

      // Clean up subscriptions
      await incomingSessionSubscription.cancel();
      await clientUpdatesSubscription.cancel();

      // 6. Stop server
      await transferServer.stop();

      // 7. Verify file was saved in download directory
      final downloadPath = await settingsRepo.getDownloadPath();
      final destFile = File('$downloadPath/test_send.txt');

      expect(await destFile.exists(), true, reason: 'Destination file should exist');
      final contents = await destFile.readAsString();
      expect(contents, 'Hello, this is a local loopback TLS file transfer test!');

      // Check client state ended in completed
      expect(clientUpdates.last.status, TransferStatus.completed);
    });
  });
}
