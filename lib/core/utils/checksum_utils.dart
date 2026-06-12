import 'dart:io';
import 'package:crypto/crypto.dart';

class ChecksumUtils {
  /// Computes the SHA-256 checksum of a file in a memory-efficient streamed manner.
  static Future<String> calculateSha256(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException("File not found for checksum calculation", filePath);
    }
    
    final stream = file.openRead();
    final hash = await sha256.bind(stream).first;
    return hash.toString();
  }

  /// Helper to compare two checksums case-insensitively
  static bool verifyChecksum(String checksumA, String checksumB) {
    return checksumA.trim().toLowerCase() == checksumB.trim().toLowerCase();
  }
}
