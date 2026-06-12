import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/export.dart';

class CertManager {
  static const String _certFileName = 'universal_share_cert.crt';
  static const String _keyFileName = 'universal_share_key.key';

  String? _cachedCertPem;
  String? _cachedKeyPem;
  String? _cachedFingerprint;

  String get certPem => _cachedCertPem ?? '';
  String get keyPem => _cachedKeyPem ?? '';
  String get fingerprint => _cachedFingerprint ?? '';

  /// Initialize the CertManager, generating keys and certificate if they don't exist yet.
  Future<void> init() async {
    final directory = await getApplicationSupportDirectory();
    final certFile = File('${directory.path}/$_certFileName');
    final keyFile = File('${directory.path}/$_keyFileName');

    if (await certFile.exists() && await keyFile.exists()) {
      _cachedCertPem = await certFile.readAsString();
      _cachedKeyPem = await keyFile.readAsString();
    } else {
      // Generate key pair
      final pair = CryptoUtils.generateRSAKeyPair(keySize: 2048);
      final privKey = pair.privateKey as RSAPrivateKey;
      final pubKey = pair.publicKey as RSAPublicKey;

      // Generate CSR
      final dn = {
        'CN': 'UniversalShare-Device',
        'O': 'UniversalShare',
        'OU': 'LocalTransfer',
      };
      
      // X509Utils handles building the ASN.1 structure
      final csrPem = X509Utils.generateRsaCsrPem(dn, privKey, pubKey);
      
      // Generate X509 Self-Signed Certificate valid for 10 years (3650 days)
      final certPemStr = X509Utils.generateSelfSignedCertificate(
        privKey,
        csrPem,
        3650,
      );

      final privKeyPemStr = CryptoUtils.encodeRSAPrivateKeyToPem(privKey);

      // Write to persistent storage
      await certFile.writeAsString(certPemStr);
      await keyFile.writeAsString(privKeyPemStr);

      _cachedCertPem = certPemStr;
      _cachedKeyPem = privKeyPemStr;
    }

    _cachedFingerprint = _calculateFingerprint(_cachedCertPem!);
  }

  /// Calculates the SHA-256 fingerprint of the X.509 certificate DER bytes.
  String _calculateFingerprint(String pem) {
    final cleanPem = pem
        .replaceAll('-----BEGIN CERTIFICATE-----', '')
        .replaceAll('-----END CERTIFICATE-----', '')
        .replaceAll('\r', '')
        .replaceAll('\n', '')
        .trim();
    
    final derBytes = base64.decode(cleanPem);
    final hashBytes = sha256.convert(derBytes).bytes;
    
    // Format fingerprint as AA:BB:CC:DD...
    return hashBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }

  /// Returns a SecurityContext pre-configured with the certificate and private key
  SecurityContext getSecurityContext() {
    if (_cachedCertPem == null || _cachedKeyPem == null) {
      throw StateError("CertManager must be initialized before retrieving SecurityContext");
    }

    final context = SecurityContext(withTrustedRoots: false);
    
    final certBytes = utf8.encode(_cachedCertPem!);
    final keyBytes = utf8.encode(_cachedKeyPem!);

    context.useCertificateChainBytes(certBytes);
    context.usePrivateKeyBytes(keyBytes);

    return context;
  }
}