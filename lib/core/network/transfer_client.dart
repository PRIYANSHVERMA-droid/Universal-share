import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../constants/app_constants.dart';
import '../models/history_entry_model.dart';
import '../models/transfer_file_model.dart';
import '../models/transfer_session_model.dart';
import '../storage/history_repository.dart';
import '../utils/checksum_utils.dart';
import 'cert_manager.dart';

class TransferClient {
  final CertManager _certManager;
  final HistoryRepository _historyRepository;

  // Active sending session
  TransferSessionModel? _activeSession;
  bool _isCancelled = false;

  final StreamController<TransferSessionModel> _sessionUpdatesController =
      StreamController<TransferSessionModel>.broadcast();

  Stream<TransferSessionModel> get sessionUpdates => _sessionUpdatesController.stream;

  TransferClient(this._certManager, this._historyRepository);

  /// Cancel the active outgoing transfer session
  Future<void> cancelSession() async {
    _isCancelled = true;
    final session = _activeSession;
    if (session == null) return;

    try {
      // TODO: Make a real network call to notify the receiver about cancellation
    } catch (_) {}

    final cancelledSession = session.copyWith(status: TransferStatus.cancelled);
    _sessionUpdatesController.add(cancelledSession);
    _activeSession = null;
  }

  /// Initiates an outgoing file transfer session to a peer device.
  Future<void> sendFiles({
    required String peerIp,
    required int peerPort,
    required String peerId,
    required String peerName,
    required String peerPlatform,
    required String? peerFingerprint,
    required String localDeviceId,
    required String localDeviceName,
    required List<File> filesToSend,
  }) async {
    _isCancelled = false;
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    // Prepare files metadata
    final List<TransferFileModel> filesList = [];
    for (final file in filesToSend) {
      final size = await file.length();
      final name = file.path.split(Platform.pathSeparator).last;
      filesList.add(TransferFileModel(
        name: name,
        path: file.path,
        size: size,
        status: TransferStatus.pending,
      ));
    }

    var session = TransferSessionModel(
      id: sessionId,
      peerId: peerId,
      peerName: peerName,
      peerPlatform: peerPlatform,
      isOutgoing: true,
      files: filesList,
      status: TransferStatus.pending,
    );

    _activeSession = session;
    _sessionUpdatesController.add(session);

    HttpClient? httpClient;
    try {
      httpClient = _createSecureClient(peerFingerprint);
      
      // 1. Send Transfer Request
      session = session.copyWith(status: TransferStatus.pending);
      _activeSession = session;
      _sessionUpdatesController.add(session);

      final requestBody = json.encode({
        'senderId': localDeviceId,
        'senderName': localDeviceName,
        'senderPlatform': Platform.operatingSystem,
        'certFingerprint': _certManager.fingerprint,
        'files': filesList.map((f) => {
          'name': f.name,
          'size': f.size,
          'relativePath': f.relativePath,
        }).toList(),
      });

      final req = await httpClient.postUrl(Uri.parse('https://$peerIp:$peerPort/transfer-request'));
      req.headers.contentType = ContentType.json;
      req.write(requestBody);
      
      final res = await req.close();
      if (res.statusCode != 200) {
        throw StateError("Transfer request declined by receiver (Status: ${res.statusCode})");
      }

      final resBody = await res.transform(utf8.decoder).join();
      final Map<String, dynamic> resJson = json.decode(resBody);
      final String remoteSessionId = resJson['sessionId'] as String;

      // Update session status to transferring
      session = session.copyWith(
        id: remoteSessionId,
        status: TransferStatus.transferring,
      );
      _activeSession = session;
      _sessionUpdatesController.add(session);

      // 2. Upload files sequentially
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < filesList.length; i++) {
        if (_isCancelled) break;

        var fileModel = session.files[i];
        
        // Update file status to transferring
        _updateFileStatus(i, TransferStatus.transferring);

        final file = File(fileModel.path);
        
        // Calculate SHA-256 hash first
        final checksum = await ChecksumUtils.calculateSha256(file.path);
        
        if (_isCancelled) break;

        final putReq = await httpClient.putUrl(
          Uri.parse('https://$peerIp:$peerPort/transfer/$remoteSessionId/file/$i'),
        );
        putReq.headers.add('x-file-checksum', checksum);
        putReq.contentLength = fileModel.size;

        int bytesSent = 0;
        final uploadStream = _createUploadStream(file, (sent) {
          bytesSent = sent;
          final elapsedSec = stopwatch.elapsedMilliseconds / 1000.0;
          final speed = elapsedSec > 0 ? bytesSent / elapsedSec : 0.0;
          final remainingBytes = fileModel.size - bytesSent;
          final eta = speed > 0 ? remainingBytes / speed : 0.0;

          _updateFileProgress(i, bytesSent, speed, eta);
        });

        await putReq.addStream(uploadStream);
        final putRes = await putReq.close();

        if (putRes.statusCode == 200) {
          _updateFileStatus(i, TransferStatus.completed);
        } else {
          final errBody = await putRes.transform(utf8.decoder).join();
          throw StateError("File upload failed: $errBody");
        }
      }

      if (_isCancelled) {
        // Send cancel request
        final cancelReq = await httpClient.postUrl(
          Uri.parse('https://$peerIp:$peerPort/transfer/$remoteSessionId/cancel'),
        );
        await cancelReq.close();
        
        session = session.copyWith(status: TransferStatus.cancelled);
        _activeSession = null;
        _sessionUpdatesController.add(session);
        return;
      }

      // 3. Complete Transfer
      final completeReq = await httpClient.postUrl(
        Uri.parse('https://$peerIp:$peerPort/transfer/$remoteSessionId/complete'),
      );
      final completeRes = await completeReq.close();

      final finalStatus = completeRes.statusCode == 200 
          ? TransferStatus.completed 
          : TransferStatus.failed;

      session = session.copyWith(status: finalStatus);
      _activeSession = null;
      _sessionUpdatesController.add(session);

      // Save to history
      final historyEntry = HistoryEntryModel(
        id: remoteSessionId,
        peerName: peerName,
        peerPlatform: peerPlatform,
        isOutgoing: true,
        fileName: filesList.length == 1 
            ? filesList.first.name 
            : "${filesList.first.name} and ${filesList.length - 1} other files",
        totalSize: session.totalSize,
        timestamp: DateTime.now(),
        status: finalStatus,
        filePaths: filesList.map((f) => f.path).toList(),
      );

      await _historyRepository.addEntry(historyEntry);

    } catch (e) {
      if (_activeSession != null) {
        session = session.copyWith(status: TransferStatus.failed, errorMessage: e.toString());
        _activeSession = null;
        _sessionUpdatesController.add(session);
      }
      
      // If we failed, notify remote session cancel if we have a sessionId
      if (session.status == TransferStatus.transferring) {
        try {
          final cancelReq = await httpClient?.postUrl(
            Uri.parse('https://$peerIp:$peerPort/transfer/${session.id}/cancel'),
          );
          await cancelReq?.close();
        } catch (_) {}
      }
    } finally {
      httpClient?.close();
    }
  }

  /// Create a secure HTTP Client that verifies the server's certificate fingerprint
  HttpClient _createSecureClient(String? expectedFingerprint) {
    final client = HttpClient()
      ..connectionTimeout = AppConstants.connectionTimeout;

    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // Extract SHA-256 fingerprint from server's certificate DER bytes
      final derBytes = cert.der;
      final hashBytes = sha256.convert(derBytes).bytes;
      final presentedFingerprint = hashBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(':');

      if (expectedFingerprint != null) {
        // Perform TLS Pinning validation
        return presentedFingerprint.trim().toUpperCase() ==
            expectedFingerprint.trim().toUpperCase();
      }

      // If we don't have the fingerprint (e.g. first discovery or fallback), 
      // we trust the cert during pairing (we'll capture and verify the PIN on the screen)
      return true;
    };

    return client;
  }

  /// Custom stream generator to wrap file reading and track progress
  Stream<List<int>> _createUploadStream(File file, Function(int) onProgress) async* {
    final stream = file.openRead();
    int sentBytes = 0;
    
    await for (final chunk in stream) {
      if (_isCancelled) {
        break;
      }
      sentBytes += chunk.length;
      onProgress(sentBytes);
      yield chunk;
    }
  }

  // Update status of single file in active session
  void _updateFileStatus(int index, TransferStatus status) {
    final session = _activeSession;
    if (session == null) return;

    final updatedFiles = List<TransferFileModel>.from(session.files);
    updatedFiles[index] = updatedFiles[index].copyWith(status: status);

    final updatedSession = session.copyWith(files: updatedFiles);
    _activeSession = updatedSession;
    _sessionUpdatesController.add(updatedSession);
  }

  // Update progress of single file in active session
  void _updateFileProgress(int index, int bytesTransferred, double speed, double eta) {
    final session = _activeSession;
    if (session == null) return;

    final updatedFiles = List<TransferFileModel>.from(session.files);
    updatedFiles[index] = updatedFiles[index].copyWith(bytesTransferred: bytesTransferred);

    final updatedSession = session.copyWith(
      files: updatedFiles,
      speed: speed,
      eta: eta,
    );
    _activeSession = updatedSession;
    _sessionUpdatesController.add(updatedSession);
  }
}
