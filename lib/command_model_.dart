library;

/// نموذج الأمر
class DeviceCommand {
  final String id;
  final String deviceId;
  final int relayId;
  final bool targetState;
  final String source; // "local" أو "cloud"
  final String userId;
  final DateTime timestamp;
  final String status; // "pending", "executing", "executed", "failed"
  final String? errorMessage;

  DeviceCommand({
    required this.id,
    required this.deviceId,
    required this.relayId,
    required this.targetState,
    required this.source,
    required this.userId,
    required this.timestamp,
    required this.status,
    this.errorMessage,
  });

  factory DeviceCommand.fromJson(Map<String, dynamic> json) {
    return DeviceCommand(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      relayId: json['relayId'] as int,
      targetState: json['targetState'] as bool,
      source: json['source'] as String,
      userId: json['userId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'relayId': relayId,
      'targetState': targetState,
      'source': source,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'errorMessage': errorMessage,
    };
  }
}