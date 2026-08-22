library;

/// نموذج الجدولة (Schedule) للروليه
/// يسمح بتشغيل/إيقاف الروليه تلقائياً في أوقات محددة
class RelaySchedule {
  /// معرّف الجدولة (فريد)
  final String id;

  /// معرّف الروليه
  final int relayId;

  /// معرّف اللوحة
  final String deviceId;

  /// اسم الجدولة (مثل: "تشغيل الإضاءة صباحاً")
  final String name;

  /// الحالة المطلوبة (true = تشغيل، false = إيقاف)
  final bool targetState;

  /// الساعة (0-23)
  final int hour;

  /// الدقيقة (0-59)
  final int minute;

  /// أيام التكرار
  /// مثال: [1, 3, 5] = الأحد، الثلاثاء، الخميس
  /// 0 = الأحد، 1 = الاثنين، ... 6 = السبت
  final List<int> repeatDays;

  /// هل الجدولة مفعلة؟
  final bool isEnabled;

  /// نوع الجدولة
  /// "once" = مرة واحدة
  /// "daily" = يومي
  /// "weekly" = أسبوعي
  /// "monthly" = شهري
  final String repeatType;

  /// تاريخ الانتهاء (للجدولة الموحدة)
  final DateTime? endDate;

  /// الوصف
  final String? description;

  /// وقت الإنشاء
  final DateTime createdAt;

  /// آخر تعديل
  final DateTime updatedAt;

  RelaySchedule({
    required this.id,
    required this.relayId,
    required this.deviceId,
    required this.name,
    required this.targetState,
    required this.hour,
    required this.minute,
    this.repeatDays = const [0, 1, 2, 3, 4, 5, 6], // كل الأيام
    this.isEnabled = true,
    this.repeatType = 'daily',
    this.endDate,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ============================================================================
  // التحويل من/إلى JSON
  // ============================================================================

  factory RelaySchedule.fromJson(Map<String, dynamic> json) {
    return RelaySchedule(
      id: json['id'] as String,
      relayId: json['relayId'] as int,
      deviceId: json['deviceId'] as String,
      name: json['name'] as String,
      targetState: json['targetState'] as bool,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      repeatDays: List<int>.from(json['repeatDays'] as List? ?? []),
      isEnabled: json['isEnabled'] as bool? ?? true,
      repeatType: json['repeatType'] as String? ?? 'daily',
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      description: json['description'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relayId': relayId,
      'deviceId': deviceId,
      'name': name,
      'targetState': targetState,
      'hour': hour,
      'minute': minute,
      'repeatDays': repeatDays,
      'isEnabled': isEnabled,
      'repeatType': repeatType,
      'endDate': endDate?.toIso8601String(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // ============================================================================
  // الدوال المساعدة
  // ============================================================================

  /// الوقت بصيغة نصية (مثل: "07:30")
  String get timeDisplay => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// أسماء الأيام المختارة
  List<String> get selectedDaysNames {
    const dayNames = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    return repeatDays.map((day) => dayNames[day]).toList();
  }

  /// هل هذا اليوم مشمول في الجدولة؟
  bool isDayIncluded(int weekday) {
    // weekday: 0=الأحد، 1=الاثنين، ... 6=السبت
    return repeatDays.contains(weekday % 7);
  }

  /// هل يجب تنفيذ الجدولة الآن؟
  bool shouldExecuteNow() {
    if (!isEnabled) return false;

    final now = DateTime.now();
    final scheduleTime = DateTime(now.year, now.month, now.day, hour, minute);
    
    // هل الوقت الحالي مطابق للجدولة؟ (مع تفاوت 1 دقيقة)
    final timeDiff = (now.difference(scheduleTime).inSeconds).abs();
    if (timeDiff > 60) return false;

    // هل اليوم مشمول؟
    final isToday = isDayIncluded(now.weekday % 7);
    if (!isToday) return false;

    // هل تخطينا تاريخ الانتهاء؟
    if (endDate != null && now.isAfter(endDate!)) return false;

    return true;
  }

  /// نسخة محدثة
  RelaySchedule copyWith({
    String? id,
    int? relayId,
    String? deviceId,
    String? name,
    bool? targetState,
    int? hour,
    int? minute,
    List<int>? repeatDays,
    bool? isEnabled,
    String? repeatType,
    DateTime? endDate,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RelaySchedule(
      id: id ?? this.id,
      relayId: relayId ?? this.relayId,
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      targetState: targetState ?? this.targetState,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatDays: repeatDays ?? this.repeatDays,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatType: repeatType ?? this.repeatType,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'RelaySchedule($name at $timeDisplay)';
}