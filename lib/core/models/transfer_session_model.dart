import 'transfer_file_model.dart';

class TransferSessionModel {
  final String id;
  final String peerId;
  final String peerName;
  final String peerPlatform;
  final bool isOutgoing;
  final List<TransferFileModel> files;
  final TransferStatus status;
  final double speed; // Bytes per second
  final double eta; // Seconds remaining
  final String? pin; // 4-digit pairing PIN if pairing is required
  final bool pairingRequired;
  final String? errorMessage;

  TransferSessionModel({
    required this.id,
    required this.peerId,
    required this.peerName,
    required this.peerPlatform,
    required this.isOutgoing,
    required this.files,
    this.status = TransferStatus.pending,
    this.speed = 0.0,
    this.eta = 0.0,
    this.pin,
    this.pairingRequired = false,
    this.errorMessage,
  });

  int get totalSize => files.fold(0, (sum, file) => sum + file.size);
  
  int get bytesTransferred => files.fold(0, (sum, file) => sum + file.bytesTransferred);
  
  double get progress => totalSize > 0 ? bytesTransferred / totalSize : 0.0;

  TransferSessionModel copyWith({
    String? id,
    String? peerId,
    String? peerName,
    String? peerPlatform,
    bool? isOutgoing,
    List<TransferFileModel>? files,
    TransferStatus? status,
    double? speed,
    double? eta,
    String? pin,
    bool? pairingRequired,
    String? errorMessage,
  }) {
    return TransferSessionModel(
      id: id ?? this.id,
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
      peerPlatform: peerPlatform ?? this.peerPlatform,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      files: files ?? this.files,
      status: status ?? this.status,
      speed: speed ?? this.speed,
      eta: eta ?? this.eta,
      pin: pin ?? this.pin,
      pairingRequired: pairingRequired ?? this.pairingRequired,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}