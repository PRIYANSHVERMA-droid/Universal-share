class DeviceModel {
  final String id;
  final String name;
  final String platform; // 'windows' | 'android' | 'macos' | 'ios'
  final String ip;
  final int port;
  final bool isTrusted;
  final String? certFingerprint;
  final DateTime lastSeen;

  DeviceModel({
    required this.id,
    required this.name,
    required this.platform,
    required this.ip,
    required this.port,
    this.isTrusted = false,
    this.certFingerprint,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  DeviceModel copyWith({
    String? id,
    String? name,
    String? platform,
    String? ip,
    int? port,
    bool? isTrusted,
    String? certFingerprint,
    DateTime? lastSeen,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      isTrusted: isTrusted ?? this.isTrusted,
      certFingerprint: certFingerprint ?? this.certFingerprint,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platform': platform,
      'ip': ip,
      'port': port,
      'isTrusted': isTrusted,
      'certFingerprint': certFingerprint,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      platform: json['platform'] as String,
      ip: json['ip'] as String,
      port: json['port'] as int,
      isTrusted: json['isTrusted'] as bool? ?? false,
      certFingerprint: json['certFingerprint'] as String?,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}