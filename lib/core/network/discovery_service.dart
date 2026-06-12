import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:nsd/nsd.dart' as nsd;
import '../constants/app_constants.dart';
import '../models/device_model.dart';

class DiscoveryService {
  String? _localDeviceId;
  String? _localDeviceName;
  int? _localServerPort;

  nsd.Registration? _registration;
  nsd.Discovery? _discovery;
  RawDatagramSocket? _udpSocket;
  Timer? _udpBroadcastTimer;
  Timer? _peerEvictionTimer;

  // Track discovered peers
  final Map<String, DeviceModel> _discoveredPeers = {};
  
  // Stream controller to broadcast peer list updates
  final StreamController<List<DeviceModel>> _peersStreamController =
      StreamController<List<DeviceModel>>.broadcast();

  Stream<List<DeviceModel>> get peersStream => _peersStreamController.stream;

  List<DeviceModel> getDiscoveredPeers() {
    return _discoveredPeers.values.toList();
  }

  /// Start discovery services (both mDNS and UDP Broadcast fallback)
  Future<void> startDiscovery({
    required String deviceId,
    required String deviceName,
    required int serverPort,
  }) async {
    _localDeviceId = deviceId;
    _localDeviceName = deviceName;
    _localServerPort = serverPort;

    // Reset list
    _discoveredPeers.clear();
    _notifyPeersChanged();

    // 1. Start mDNS
    await _startMdns();

    // 2. Start UDP Broadcast fallback
    await _startUdpFallback();

    // 3. Start Peer Eviction Checker (runs every 3 seconds)
    _peerEvictionTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkPeerEviction();
    });
  }

  /// Stop all discovery and release sockets/timers
  Future<void> stopDiscovery() async {
    _udpBroadcastTimer?.cancel();
    _peerEvictionTimer?.cancel();
    
    if (_registration != null) {
      await nsd.unregister(_registration!);
      _registration = null;
    }

    if (_discovery != null) {
      await nsd.stopDiscovery(_discovery!);
      _discovery = null;
    }

    _udpSocket?.close();
    _udpSocket = null;

    _discoveredPeers.clear();
    _notifyPeersChanged();
  }

  // Helper to trigger updates to listeners
  void _notifyPeersChanged() {
    if (!_peersStreamController.isClosed) {
      _peersStreamController.add(getDiscoveredPeers());
    }
  }

  // Update or insert a peer in our tracking list
  void _updatePeer(DeviceModel peer) {
    // Check if we are updating an existing trusted status (we'll preserve it if set in UI)
    final existing = _discoveredPeers[peer.id];
    _discoveredPeers[peer.id] = peer.copyWith(
      isTrusted: existing?.isTrusted ?? peer.isTrusted,
      lastSeen: DateTime.now(),
    );
    _notifyPeersChanged();
  }

  // Remove peers we haven't seen in peerExpiryDuration (10s)
  void _checkPeerEviction() {
    final now = DateTime.now();
    bool changed = false;

    _discoveredPeers.removeWhere((id, peer) {
      final difference = now.difference(peer.lastSeen);
      if (difference > AppConstants.peerExpiryDuration) {
        changed = true;
        return true;
      }
      return false;
    });

    if (changed) {
      _notifyPeersChanged();
    }
  }

  // ==========================================
  // mDNS Zeroconf Implementation
  // ==========================================

  Future<void> _startMdns() async {
    try {
      // On Windows the nsd plugin can emit platform-channel messages
      // from a non-platform thread which leads to a runtime error.
      // Use UDP broadcast fallback on Windows to avoid that plugin issue.
      if (Platform.isWindows) {
        return;
      }
      // Register our service
      _registration = await nsd.register(nsd.Service(
        name: _localDeviceName,
        type: AppConstants.mdnsServiceType,
        port: _localServerPort,
        txt: {
          'id': Uint8List.fromList(utf8.encode(_localDeviceId!)),
          'platform': Uint8List.fromList(utf8.encode(Platform.operatingSystem)),
        },
      ));

      // Start browsing for peers
      _discovery = await nsd.startDiscovery(
        AppConstants.mdnsServiceType,
        ipLookupType: nsd.IpLookupType.any,
      );

      _discovery!.addListener(() {
        _handleMdnsUpdate(_discovery!.services);
      });
    } catch (_) {
      // mDNS registration or browsing failed (can happen if mDNS subsystem is broken)
      // We still fall back to UDP broadcast
    }
  }

  void _handleMdnsUpdate(List<nsd.Service> services) {
    for (final service in services) {
      try {
        final txt = service.txt;
        if (txt == null) continue;

        final peerIdBytes = txt['id'];
        final peerPlatformBytes = txt['platform'];
        if (peerIdBytes == null) continue;
        final peerId = utf8.decode(peerIdBytes);
        final peerPlatform = peerPlatformBytes != null ? utf8.decode(peerPlatformBytes) : 'android';

        if (peerId == _localDeviceId) continue;

        // Extract IP address from addresses or fallback to host
        String? ipAddress;
        if (service.addresses != null && service.addresses!.isNotEmpty) {
          ipAddress = service.addresses!.first.address;
        } else {
          ipAddress = service.host;
        }

        if (ipAddress == null || service.port == null) continue;

        final peer = DeviceModel(
          id: peerId,
          name: service.name ?? 'Unknown Device',
          platform: peerPlatform,
          ip: ipAddress,
          port: service.port!,
        );

        _updatePeer(peer);
      } catch (_) {
        // Ignore single parse errors
      }
    }
  }

  // ==========================================
  // UDP Broadcast Fallback Implementation
  // ==========================================

  Future<void> _startUdpFallback() async {
    try {
      // Bind socket
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        AppConstants.udpBroadcastPort,
        reuseAddress: true,
        reusePort: true,
      );
      _udpSocket!.broadcastEnabled = true;

      // Listen for incoming UDP broadcast pings
      _udpSocket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpSocket!.receive();
          if (datagram != null) {
            _handleUdpPacket(datagram);
          }
        }
      });

      // Start periodic broadcast timer (ping every 3 seconds)
      _udpBroadcastTimer = Timer.periodic(AppConstants.udpBroadcastInterval, (_) {
        _sendUdpPing();
      });
    } catch (_) {
      // UDP binding failed (e.g. port already fully locked). Fallback to mDNS.
    }
  }

  void _sendUdpPing() {
    if (_udpSocket == null || _localDeviceId == null) return;

    try {
      final packetData = json.encode({
        'id': _localDeviceId,
        'name': _localDeviceName,
        'platform': Platform.operatingSystem,
        'port': _localServerPort,
      });

      final bytes = utf8.encode(packetData);
      
      // Send to global IPv4 broadcast address
      _udpSocket!.send(
        bytes,
        InternetAddress('255.255.255.255'),
        AppConstants.udpBroadcastPort,
      );
    } catch (_) {
      // Ignore network broadcast errors
    }
  }

  void _handleUdpPacket(Datagram datagram) {
    try {
      final rawStr = utf8.decode(datagram.data);
      final Map<String, dynamic> jsonMap = json.decode(rawStr);

      final peerId = jsonMap['id'] as String?;
      if (peerId == null || peerId == _localDeviceId) return;

      final peerName = jsonMap['name'] as String? ?? 'Unknown Device';
      final peerPlatform = jsonMap['platform'] as String? ?? 'android';
      final peerPort = jsonMap['port'] as int?;

      if (peerPort == null) return;

      // Use the sender's IP address as the connection target
      final peerIp = datagram.address.address;

      final peer = DeviceModel(
        id: peerId,
        name: peerName,
        platform: peerPlatform,
        ip: peerIp,
        port: peerPort,
      );

      _updatePeer(peer);
    } catch (_) {
      // Ignore corrupt UDP packets
    }
  }
}