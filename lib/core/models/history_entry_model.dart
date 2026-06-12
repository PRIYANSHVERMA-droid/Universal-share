import 'transfer_file_model.dart';

class HistoryEntryModel {
  final String id;
  final String peerName;
  final String peerPlatform;
  final bool isOutgoing;
  final String fileName;
  final int totalSize;
  final DateTime timestamp;
  final TransferStatus status;
  final List<String> filePaths;

  HistoryEntryModel({
    required this.id,
    required this.peerName,
    required this.peerPlatform,
    required this.isOutgoing,
    required this.fileName,
    required this.totalSize,
    required this.timestamp,
    required this.status,
    required this.filePaths,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'peerName': peerName,
      'peerPlatform': peerPlatform,
      'isOutgoing': isOutgoing,
      'fileName': fileName,
      'totalSize': totalSize,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'filePaths': filePaths,
    };
  }

  factory HistoryEntryModel.fromJson(Map<String, dynamic> json) {
    return HistoryEntryModel(
      id: json['id'] as String,
      peerName: json['peerName'] as String,
      peerPlatform: json['peerPlatform'] as String,
      isOutgoing: json['isOutgoing'] as bool,
      fileName: json['fileName'] as String,
      totalSize: json['totalSize'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: TransferStatus.values.byName(json['status'] as String),
      filePaths: List<String>.from(json['filePaths'] as List),
    );
  }
}