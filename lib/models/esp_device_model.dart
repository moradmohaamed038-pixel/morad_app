library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'relay_model.dart';
import 'sensor_model.dart';

/// نموذج لوحة ESP32 (حقيقية أو افتراضية)
class EspDevice {
  // ============================================================================
  // البيانات الأساسية
  // ============================================================================

  /// معرّف اللوحة (فريد)
  final String id;

  /// اسم اللوحة (مثل: "لوحة المطبخ")
  final String name;

  /// الموقع الفيزيائي (مثل: "المطبخ")
  final String location;

  /// كلمة المرور المحلية
  final String localPin;

  /// عنوان IP اللوحة (للاتصال المحلي)
  /// null إذا كانت افتراضية أو غير متصلة
  final String? ipAddress;

  /// بورت الاتصال (عادة 8080 أو 81)
  final int? port;

  /// معرّف المالك (uid من Firebase)
  final String ownerId;

  /// حالة الاتصال
  /// "connected" = متصلة الآن
  /// "offline" = غير متصلة
  /// "demo" = افتراضية
  final String status;

  /// هل هذه لوحة افتراضية؟
  final bool isDemo;

  /// آخر مرة رأينا اللوحة متصلة
  final DateTime lastSeen;

  /// وقت الإنشاء
  final DateTime createdAt;

  /// آخر تحديث
  final DateTime updatedAt;

  // ============================================================================
  // الروليهات والحساسات
  // ============================================================================

  /// قائمة الروليهات (المفاتيح الكهربائية)
  /// روليه = مفتاح يمكن تشغيله وإيقافه
  final List<Relay> relays;

  /// قائمة الحساسات
  /// حساس = جهاز يقيس شيء ما (درجة حرارة، رطوبة، إلخ)
  final List<Sensor> sensors;

  // ============================================================================
  // الصلاحيات والمشاركة
  // ============================================================================

  /// المستخدمون الذين يمكنهم رؤية هذه اللوحة
  /// مثال: {"uid_002": "viewer", "uid_003": "controller"}
  /// "viewer" = مشاهدة فقط
  /// "controller" = تحكم كامل
  /// "admin" = إدارة شاملة
  final Map<String, String> sharedWith;

  // ============================================================================
  // البيانات الاختيارية
  // ============================================================================

  /// وصف اللوحة
  final String? description;

  /// صورة اللوحة (URL)
  final String? imageUrl;

  /// نوع اللوحة (مثل: "ESP32", "Arduino", "Demo")
  final String deviceType;

  /// إصدار البرنامج الثابت
  final String? firmwareVersion;

  /// عدد الروليهات المدعومة
  final int maxRelays;

  /// عدد الحساسات المدعومة
  final int maxSensors;

  // ============================================================================
  // البناء
  // ============================================================================

  EspDevice({
    required this.id,
    required this.name,
    required this.location,
    required this.localPin,
    required this.ownerId,
    this.ipAddress,
    this.port = 8080,
    this.status = 'offline',
    this.isDemo = false,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.relays = const [],
    this.sensors = const [],
    this.sharedWith = const {},
    this.description,
    this.imageUrl,
    this.deviceType = 'ESP32',
    this.firmwareVersion,
    this.maxRelays = 8,
    this.maxSensors = 8,
  })  : lastSeen = lastSeen ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ============================================================================
  // التحويل من/إلى JSON
  // ============================================================================

  /// تحويل من JSON (من Firebase)
  factory EspDevice.fromJson(Map<String, dynamic> json) {
    return EspDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      localPin: json['localPin'] as String,
      ownerId: json['ownerId'] as String,
      ipAddress: json['ipAddress'] as String?,
      port: json['port'] as int? ?? 8080,
      status: json['status'] as String? ?? 'offline',
      isDemo: json['isDemo'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      relays: (json['relays'] as List<dynamic>?)
              ?.map((r) => Relay.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      sensors: (json['sensors'] as List<dynamic>?)
              ?.map((s) => Sensor.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      sharedWith: Map<String, String>.from(json['sharedWith'] as Map? ?? {}),
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      deviceType: json['deviceType'] as String? ?? 'ESP32',
      firmwareVersion: json['firmwareVersion'] as String?,
      maxRelays: json['maxRelays'] as int? ?? 8,
      maxSensors: json['maxSensors'] as int? ?? 8,
    );
  }

  /// تحويل إلى JSON (لحفظ في Firebase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'localPin': localPin,
      'ownerId': ownerId,
      'ipAddress': ipAddress,
      'port': port,
      'status': status,
      'isDemo': isDemo,
      'lastSeen': lastSeen.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'relays': relays.map((r) => r.toJson()).toList(),
      'sensors': sensors.map((s) => s.toJson()).toList(),
      'sharedWith': sharedWith,
      'description': description,
      'imageUrl': imageUrl,
      'deviceType': deviceType,
      'firmwareVersion': firmwareVersion,
      'maxRelays': maxRelays,
      'maxSensors': maxSensors,
    };
  }

  // ============================================================================
  // الدوال المساعدة
  // ============================================================================

  /// نسخة محدثة من اللوحة
  EspDevice copyWith({
    String? id,
    String? name,
    String? location,
    String? localPin,
    String? ipAddress,
    int? port,
    String? status,
    bool? isDemo,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Relay>? relays,
    List<Sensor>? sensors,
    Map<String, String>? sharedWith,
    String? description,
    String? imageUrl,
    String? deviceType,
    String? firmwareVersion,
    int? maxRelays,
    int? maxSensors,
    String? ownerId,
  }) {
    return EspDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      localPin: localPin ?? this.localPin,
      ownerId: ownerId ?? this.ownerId,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      status: status ?? this.status,
      isDemo: isDemo ?? this.isDemo,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      relays: relays ?? this.relays,
      sensors: sensors ?? this.sensors,
      sharedWith: sharedWith ?? this.sharedWith,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      deviceType: deviceType ?? this.deviceType,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      maxRelays: maxRelays ?? this.maxRelays,
      maxSensors: maxSensors ?? this.maxSensors,
    );
  }

  /// هل اللوحة متصلة الآن؟
  bool get isConnected => status == 'connected';

  /// هل اللوحة افتراضية؟
  bool get isDemoDevice => isDemo || status == 'demo';

  /// هل يمكن الاتصال بها محلياً؟
  bool get canConnectLocally => ipAddress != null && isConnected;

  /// عدد الروليهات المفعلة
  int get activeRelaysCount => relays.where((r) => r.state).length;

  /// عدد الحساسات
  int get sensorsCount => sensors.length;

  /// هل اللوحة لديها روليهات؟
  bool get hasRelays => relays.isNotEmpty;

  /// هل اللوحة لديها حساسات؟
  bool get hasSensors => sensors.isNotEmpty;

  /// الاتصال الآمن (HTTPS أم HTTP)
  String get connectionUrl => 'http://$ipAddress:$port';

  @override
  String toString() {
    return 'EspDevice(id: $id, name: $name, status: $status, '
        'relays: ${relays.length}, sensors: ${sensors.length})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EspDevice &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ status.hashCode;
}
