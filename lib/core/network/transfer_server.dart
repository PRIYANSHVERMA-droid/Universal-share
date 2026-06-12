import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../constants/app_constants.dart';
import '../models/history_entry_model.dart';
import '../models/transfer_file_model.dart';
import '../models/transfer_session_model.dart';
import '../storage/history_repository.dart';
import '../storage/settings_repository.dart';
import '../storage/trusted_devices_repository.dart';
import 'cert_manager.dart';

class TransferServer {
  final CertManager _certManager;
  final SettingsRepository _settingsRepository;
  final TrustedDevicesRepository _trustedDevicesRepository;
  final HistoryRepository _historyRepository;

  HttpServer? _server;
  int? _activePort;
  int? get port => _activePort;

  // Active sessions map: sessionId -> Session
  final Map<String, TransferSessionModel> _activeSessions = {};
  
  // Completers for user acceptance: sessionId -> Completer<bool>
  final Map<String, Completer<bool>> _acceptCompleters = {};

  // Stream Controllers
  final StreamController<TransferSessionModel> _incomingSessionController =
      StreamController<TransferSessionModel>.broadcast();
  final StreamController<TransferSessionModel> _sessionUpdatesController =
      StreamController<TransferSessionModel>.broadcast();

  Stream<TransferSessionModel> get incomingSessions => _incomingSessionController.stream;
  Stream<TransferSessionModel> get sessionUpdates => _sessionUpdatesController.stream;

  TransferServer(
    this._certManager,
    this._settingsRepository,
    this._trustedDevicesRepository,
    this._historyRepository,
  );

  /// Start the TLS HTTP server. It will scan ports sequentially if the default port is occupied.
  Future<int> start() async {
    final startPort = AppConstants.defaultServerPort;
    final endPort = AppConstants.maxServerPortRange;

    final router = Router();
    _setupRoutes(router);

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);

    final context = _certManager.getSecurityContext();

    for (int port = startPort; port <= endPort; port++) {
      try {
        _server = await HttpServer.bindSecure(
          InternetAddress.anyIPv4,
          port,
          context,
        );
        shelf_io.serveRequests(_server!, handler);
        _activePort = port;
        return port;
      } catch (e) {
        if (port == endPort) {
          throw StateError("Failed to bind transfer server to any port in range $startPort - $endPort: $e");
        }
        // Otherwise, continue to check next port
      }
    }
    throw StateError("Unreachable");
  }

  /// Stop the transfer server
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _activePort = null;
    _activeSessions.clear();
    _acceptCompleters.clear();
  }

  /// Accept an incoming transfer request
  void acceptSession(String sessionId) {
    final completer = _acceptCompleters[sessionId];
    if (completer != null && !completer.isCompleted) {
      completer.complete(true);
    }
  }

  /// Decline an incoming transfer request
  void declineSession(String sessionId) {
    final completer = _acceptCompleters[sessionId];
    if (completer != null && !completer.isCompleted) {
      completer.complete(false);
    }
  }

  /// Setup the endpoints for the server router
  void _setupRoutes(Router router) {
    
    // 1. POST /transfer-request
    router.post('/transfer-request', (Request request) async {
      try {
        final body = await request.readAsString();
        final Map<String, dynamic> jsonMap = json.decode(body);

        final senderId = jsonMap['senderId'] as String;
        final senderName = jsonMap['senderName'] as String;
        final senderPlatform = jsonMap['senderPlatform'] as String;
        final senderFingerprint = jsonMap['certFingerprint'] as String;
        final filesJson = jsonMap['files'] as List;

        final downloadFolder = await _settingsRepository.getDownloadPath();

        final List<TransferFileModel> filesList = filesJson.map((f) {
          final fileMap = f as Map<String, dynamic>;
          final name = fileMap['name'] as String;
          final size = fileMap['size'] as int;
          final relativePath = fileMap['relativePath'] as String?;

          // Initial save path
          final savePath = relativePath != null 
              ? '$downloadFolder/$relativePath'
              : '$downloadFolder/$name';

          return TransferFileModel(
            name: name,
            path: savePath,
            size: size,
            relativePath: relativePath,
            status: TransferStatus.pending,
          );
        }).toList();

        final sessionId = Random().nextInt(900000000).toString();
        
        // Check pairing status
        final isTrusted = _trustedDevicesRepository.isDeviceTrusted(senderId, senderFingerprint);
        final bool autoAccept = _settingsRepository.getAutoAccept();
        
        final bool pairingRequired = !isTrusted;
        final pin = pairingRequired 
            ? (Random().nextInt(9000) + 1000).toString() 
            : null;

        final session = TransferSessionModel(
          id: sessionId,
          peerId: senderId,
          peerName: senderName,
          peerPlatform: senderPlatform,
          isOutgoing: false,
          files: filesList,
          status: TransferStatus.pending,
          pairingRequired: pairingRequired,
          pin: pin,
        );

        _activeSessions[sessionId] = session;

        // Create completer for user prompt UI
        final completer = Completer<bool>();
        _acceptCompleters[sessionId] = completer;

        // Notify UI that a request has arrived
        _incomingSessionController.add(session);

        // Await user decision (either manual or auto-accept if trusted and auto-accept enabled)
        bool accepted = false;
        if (isTrusted && autoAccept) {
          accepted = true;
          completer.complete(true);
        } else {
          accepted = await completer.future;
        }

        // Clean up completer
        _acceptCompleters.remove(sessionId);

        if (!accepted) {
          _activeSessions.remove(sessionId);
          final updatedSession = session.copyWith(status: TransferStatus.cancelled);
          _sessionUpdatesController.add(updatedSession);
          return Response.forbidden(json.encode({'accepted': false, 'error': 'declined'}));
        }

        // If accepted and pairing was required, automatically trust this device
        if (pairingRequired) {
          await _trustedDevicesRepository.addTrustedDevice(
            senderId,
            senderName,
            senderPlatform,
            senderFingerprint,
          );
        }

        // Update session status to transferring
        final updatedSession = session.copyWith(status: TransferStatus.transferring);
        _activeSessions[sessionId] = updatedSession;
        _sessionUpdatesController.add(updatedSession);

        return Response.ok(json.encode({
          'accepted': true,
          'sessionId': sessionId,
          'pairingRequired': pairingRequired,
        }));
      } catch (e) {
        return Response.internalServerError(body: json.encode({'error': e.toString()}));
      }
    });

    // 2. PUT /transfer/<sessionId>/file/<index>
    router.put('/transfer/<sessionId>/file/<index>', (Request request, String sessionId, String indexStr) async {
      final session = _activeSessions[sessionId];
      if (session == null) {
        return Response.forbidden(json.encode({'error': 'session_not_found'}));
      }

      final index = int.tryParse(indexStr);
      if (index == null || index < 0 || index >= session.files.length) {
        return Response.notFound(json.encode({'error': 'file_index_not_found'}));
      }

      final expectedChecksum = request.headers['x-file-checksum'];
      if (expectedChecksum == null) {
        return Response.badRequest(body: json.encode({'error': 'missing_checksum_header'}));
      }

      var fileModel = session.files[index];
      
      // Update status to transferring
      _updateFileStatus(sessionId, index, TransferStatus.transferring, bytesTransferred: 0);

      final file = File(fileModel.path);
      
      // Ensure containing directory exists (for folder structures)
      await file.parent.create(recursive: true);

      IOSink? fileSink;
      try {
        fileSink = file.openWrite();
        
        // Setup SHA-256 hashing stream converter in parallel
        var hashAccumulator = <int>[];
        
        int bytesWritten = 0;
        final stopwatch = Stopwatch()..start();

        await for (final chunk in request.read()) {
          fileSink.add(chunk);
          hashAccumulator.addAll(chunk);
          bytesWritten += chunk.length;

          // Track transfer metrics (speed, eta)
          final elapsedSec = stopwatch.elapsedMilliseconds / 1000.0;
          final speed = elapsedSec > 0 ? bytesWritten / elapsedSec : 0.0;
          final remainingBytes = fileModel.size - bytesWritten;
          final eta = speed > 0 ? remainingBytes / speed : 0.0;

          _updateFileProgress(sessionId, index, bytesWritten, speed, eta);
        }

        await fileSink.close();
        fileSink = null;
        final calculatedHash = sha256.convert(hashAccumulator).toString();

        // Checksum verification
        if (calculatedHash.toLowerCase() == expectedChecksum.toLowerCase()) {
          _updateFileStatus(sessionId, index, TransferStatus.completed, checksum: calculatedHash);
          return Response.ok(json.encode({'success': true}));
        } else {
          // Checksum mismatch -> Delete corrupted file
          if (await file.exists()) {
            await file.delete();
          }
          _updateFileStatus(sessionId, index, TransferStatus.failed, errorMessage: 'Checksum verification failed');
          return Response.badRequest(body: json.encode({'success': false, 'error': 'checksum_mismatch'}));
        }
      } catch (e) {
        fileSink?.close();
        if (await file.exists()) {
          await file.delete();
        }
        _updateFileStatus(sessionId, index, TransferStatus.failed, errorMessage: e.toString());
        return Response.internalServerError(body: json.encode({'success': false, 'error': e.toString()}));
      }
    });

    // 3. POST /transfer/<sessionId>/complete
    router.post('/transfer/<sessionId>/complete', (Request request, String sessionId) async {
      final session = _activeSessions[sessionId];
      if (session == null) {
        return Response.forbidden(json.encode({'error': 'session_not_found'}));
      }

      // Check if all files succeeded or if some failed
      bool anyFailed = session.files.any((f) => f.status == TransferStatus.failed);
      final finalStatus = anyFailed ? TransferStatus.failed : TransferStatus.completed;

      final finalSession = session.copyWith(status: finalStatus);
      _activeSessions.remove(sessionId);
      _sessionUpdatesController.add(finalSession);

      // Save to History database
      final historyEntry = HistoryEntryModel(
        id: session.id,
        peerName: session.peerName,
        peerPlatform: session.peerPlatform,
        isOutgoing: false,
        fileName: session.files.length == 1 
            ? session.files.first.name 
            : "${session.files.first.name} and ${session.files.length - 1} other files",
        totalSize: session.totalSize,
        timestamp: DateTime.now(),
        status: finalStatus,
        filePaths: session.files.map((f) => f.path).toList(),
      );

      await _historyRepository.addEntry(historyEntry);

      return Response.ok(json.encode({'success': true}));
    });

    // 4. POST /transfer/<sessionId>/cancel
    router.post('/transfer/<sessionId>/cancel', (Request request, String sessionId) async {
      final session = _activeSessions[sessionId];
      if (session == null) {
        return Response.forbidden(json.encode({'error': 'session_not_found'}));
      }

      _activeSessions.remove(sessionId);
      
      // Clean up partial files
      for (final fileModel in session.files) {
        if (fileModel.status == TransferStatus.transferring) {
          final file = File(fileModel.path);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }

      final cancelledSession = session.copyWith(status: TransferStatus.cancelled);
      _sessionUpdatesController.add(cancelledSession);

      return Response.ok(json.encode({'success': true}));
    });
  }

  // Helper to update individual file status in active session
  void _updateFileStatus(
    String sessionId,
    int index,
    TransferStatus status, {
    int? bytesTransferred,
    String? checksum,
    String? errorMessage,
  }) {
    final session = _activeSessions[sessionId];
    if (session == null) return;

    final updatedFiles = List<TransferFileModel>.from(session.files);
    final file = updatedFiles[index];
    updatedFiles[index] = file.copyWith(
      status: status,
      bytesTransferred: bytesTransferred ?? file.bytesTransferred,
      checksum: checksum ?? file.checksum,
      errorMessage: errorMessage ?? file.errorMessage,
    );

    final updatedSession = session.copyWith(files: updatedFiles);
    _activeSessions[sessionId] = updatedSession;
    _sessionUpdatesController.add(updatedSession);
  }

  // Helper to update individual file progress
  void _updateFileProgress(
    String sessionId,
    int index,
    int bytesTransferred,
    double speed,
    double eta,
  ) {
    final session = _activeSessions[sessionId];
    if (session == null) return;

    final updatedFiles = List<TransferFileModel>.from(session.files);
    final file = updatedFiles[index];
    updatedFiles[index] = file.copyWith(
      bytesTransferred: bytesTransferred,
    );

    final updatedSession = session.copyWith(
      files: updatedFiles,
      speed: speed,
      eta: eta,
    );
    _activeSessions[sessionId] = updatedSession;
    _sessionUpdatesController.add(updatedSession);
  }
}
