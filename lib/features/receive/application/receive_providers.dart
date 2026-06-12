import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/transfer_session_model.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/network/transfer_server.dart';

/// Stream of incoming transfer requests requiring accept/decline confirmation.
final incomingSessionRequestsProvider = StreamProvider<TransferSessionModel>((ref) {
  final server = ref.watch(transferServerProvider);
  return server.incomingSessions;
});

/// Stream of active download session updates (progress, speed, ETA, completion).
final receiveSessionUpdatesProvider = StreamProvider<TransferSessionModel?>((ref) {
  final server = ref.watch(transferServerProvider);
  return server.sessionUpdates.map((session) => session);
});

class ReceiveController {
  final TransferServer _transferServer;

  ReceiveController(this._transferServer);

  /// Confirm and accept the incoming transfer session
  void accept(String sessionId) {
    _transferServer.acceptSession(sessionId);
  }

  /// Reject/decline the incoming transfer session
  void decline(String sessionId) {
    _transferServer.declineSession(sessionId);
  }
}

final receiveControllerProvider = Provider<ReceiveController>((ref) {
  final server = ref.watch(transferServerProvider);
  return ReceiveController(server);
});
