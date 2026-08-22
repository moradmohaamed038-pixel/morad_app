library;

/// نموذج الحساس (جهاز قياس)
class Sensor {
  /// معرّف الحساس (فريد ضمن اللوحة)
  final int id;

  /// اسم الحساس (مثل: "درجة الحرارة")
  final String name;

  /// رقم المدخل (Analog) الذي يتصل به
  /// (مثل: A0 = 0)
  final int pin;

  /// نوع الحساس
  /// "temperature" = درجة الحرارة
  /// "humidity" = الرطوبة
  /// "pressure" = الضغط
  /// "light" = الإضاءة
  /// "motion" = حركة
  /// "distance" = مسافة
  /// "gas" = غاز
  /// "soil_moisture" = رطوبة التربة
  final String type;

  /// القيمة الحالية
  /// (مثل: 25.5 للحرارة)
  final double value;

  /// وحدة القياس
  /// (مثل: "°C", "%", "hPa")
  final String unit;

  /// الحد الأدنى للقيمة
  /// (لرسم الرسوم البيانية)
  final double minValue;

  /// الحد الأقصى للقيمة
  final double maxValue;

  /// الرمز (emoji) الذي يمثل الحساس
  final String? icon;

  /// الوصف
  final String? description;

  /// اللون بصيغة hex
  final String? color;

  /// وقت آخر قراءة
  final DateTime? lastUpdate;

  /// هل هناك تحذير؟
  final bool hasWarning;

  /// قيمة التحذير
  /// (مثل: إذا كانت الحرارة أكثر من 35°)
  final double? warningThreshold;

  Sensor({
    required this.id,
    required this.name,
    required this.pin,
    required this.type,
    required this.value,
    required this.unit,
    this.minValue = 0,
    this.maxValue = 100,
    this.icon,
    this.description,
    this.color,
    this.lastUpdate,
    this.hasWarning = false,
    this.warningThreshold,
  });

  // ============================================================================
  // التحويل من/إلى JSON
  // ============================================================================

  factory Sensor.fromJson(Map<String, dynamic> json) {
    return Sensor(
      id: json['id'] as int,
      name: json['name'] as String,
      pin: json['pin'] as int,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      minValue: (json['minValue'] as num?)?.toDouble() ?? 0,
      maxValue: (json['maxValue'] as num?)?.toDouble() ?? 100,
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      color: json['color'] as String?,
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.parse(json['lastUpdate'] as String)
          : null,
      hasWarning: json['hasWarning'] as bool? ?? false,
      warningThreshold:
          (json['warningThreshold'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pin': pin,
      'type': type,
      'value': value,
      'unit': unit,
      'minValue': minValue,
      'maxValue': maxValue,
      'icon': icon,
      'description': description,
      'color': color,
      'lastUpdate': lastUpdate?.toIso8601String(),
      'hasWarning': hasWarning,
      'warningThreshold': warningThreshold,
    };
  }

  // ============================================================================
  // النسخ والتحديث
  // ============================================================================

  Sensor copyWith({
    int? id,
    String? name,
    int? pin,
    String? type,
    double? value,
    String? unit,
    double? minValue,
    double? maxValue,
    String? icon,
    String? description,
    String? color,
    DateTime? lastUpdate,
    bool? hasWarning,
    double? warningThreshold,
  }) {
    return Sensor(
      id: id ?? this.id,
      name: name ?? this.name,
      pin: pin ?? this.pin,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      color: color ?? this.color,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      hasWarning: hasWarning ?? this.hasWarning,
      warningThreshold: warningThreshold ?? this.warningThreshold,
    );
  }

  /// النسبة المئوية من الحد الأدنى إلى الأقصى
  /// (للرسوم البيانية)
  double get percentage {
    if (maxValue == minValue) return 0;
    return ((value - minValue) / (maxValue - minValue)) * 100;
  }

  /// هل القيمة في الحد الآمن؟
  bool get isSafe {
    if (warningThreshold == null) return true;
    return value <= warningThreshold!;
  }

  @override
  String toString() =>
      'Sensor(id: $id, name: $name, value: $value$unit)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sensor &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          value == other.value;

  @override
  int get hashCode => id.hashCode ^ value.hashCode;
}