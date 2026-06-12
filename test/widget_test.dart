import 'package:flutter_test/flutter_test.dart';
import 'package:universal_share/core/utils/file_size_formatter.dart';
import 'package:universal_share/core/models/device_model.dart';

void main() {
  group('FileSizeFormatter Tests', () {
    test('Format raw bytes to human readable sizes', () {
      expect(FileSizeFormatter.format(0), '0 B');
      expect(FileSizeFormatter.format(500), '500 B');
      expect(FileSizeFormatter.format(1024), '1 KB');
      expect(FileSizeFormatter.format(1024 * 1024), '1 MB');
      expect(FileSizeFormatter.format(1024 * 1024 * 3 + 512 * 1024), '3.50 MB');
      expect(FileSizeFormatter.format(1024 * 1024 * 1024 * 2), '2 GB');
    });

    test('Format transfer speeds', () {
      expect(FileSizeFormatter.formatSpeed(1024 * 1024 * 2.5), '2.50 MB/s');
    });

    test('Format remaining time (ETA)', () {
      expect(FileSizeFormatter.formatEta(30), '30s remaining');
      expect(FileSizeFormatter.formatEta(125), '2m 5s remaining');
      expect(FileSizeFormatter.formatEta(double.infinity), 'Calculating...');
    });
  });

  group('DeviceModel Serialization Tests', () {
    test('DeviceModel converts to and from JSON', () {
      final original = DeviceModel(
        id: 'test-uuid-1234',
        name: 'My Device',
        platform: 'windows',
        ip: '192.168.1.50',
        port: 53317,
        isTrusted: true,
        certFingerprint: 'AA:BB:CC',
      );

      final json = original.toJson();
      final decoded = DeviceModel.fromJson(json);

      expect(decoded.id, original.id);
      expect(decoded.name, original.name);
      expect(decoded.platform, original.platform);
      expect(decoded.ip, original.ip);
      expect(decoded.port, original.port);
      expect(decoded.isTrusted, original.isTrusted);
      expect(decoded.certFingerprint, original.certFingerprint);
    });
  });
}
