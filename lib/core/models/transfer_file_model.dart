enum TransferStatus {
  pending,
  transferring,
  completed,
  failed,
  cancelled,
}

class TransferFileModel {
  final String name;
  final String path;
  final int size;
  final int bytesTransferred;
  final TransferStatus status;
  final String? checksum;
  final String? relativePath; // Preserves directory structure for folders
  final String? errorMessage;

  TransferFileModel({
    required this.name,
    required this.path,
    required this.size,
    this.bytesTransferred = 0,
    this.status = TransferStatus.pending,
    this.checksum,
    this.relativePath,
    this.errorMessage,
  });

  double get progress => size > 0 ? bytesTransferred / size : 0.0;

  TransferFileModel copyWith({
    String? name,
    String? path,
    int? size,
    int? bytesTransferred,
    TransferStatus? status,
    String? checksum,
    String? relativePath,
    String? errorMessage,
  }) {
    return TransferFileModel(
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      status: status ?? this.status,
      checksum: checksum ?? this.checksum,
      relativePath: relativePath ?? this.relativePath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'size': size,
      'bytesTransferred': bytesTransferred,
      'status': status.name,
      'checksum': checksum,
      'relativePath': relativePath,
      'errorMessage': errorMessage,
    };
  }

  factory TransferFileModel.fromJson(Map<String, dynamic> json) {
    return TransferFileModel(
      name: json['name'] as String,
      path: json['path'] as String,
      size: json['size'] as int,
      bytesTransferred: json['bytesTransferred'] as int? ?? 0,
      status: TransferStatus.values.byName(json['status'] as String),
      checksum: json['checksum'] as String?,
      relativePath: json['relativePath'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}