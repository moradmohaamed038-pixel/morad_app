library;

/// نموذج الروليه (مفتاح كهربائي) - محدث مع المؤقتات والجدولة
class Relay {
  /// معرّف الروليه
  final int id;

  /// اسم الروليه
  final String name;

  /// رقم الـ GPIO
  final int pin;

  /// الحالة الحالية
  final bool state;

  /// الرمز
  final String? icon;

  /// الوصف
  final String? description;

  /// اللون
  final String? color;

  /// نوع الروليه
  final String type;

  /// هل هذا الروليه حرج؟
  final bool isCritical;

  // ============================================================================
  // جديد: المؤقتات والجدولة
  // ============================================================================

  /// معرّفات المؤقتات النشطة (الجارية)
  /// (علاقة مع RelayTimer)
  final List<String> activeTimerIds;

  /// معرّفات الجداول المرتبطة
  /// (علاقة مع RelaySchedule)
  final List<String> scheduleIds;

  /// هل الروليه تحت السيطرة التلقائية (جدولة أو مؤقت)؟
  final bool isUnderAutomation;

  /// وقت آخر تغيير يدوي
  final DateTime? lastManualChange;

  Relay({
    required this.id,
    required this.name,
    required this.pin,
    required this.state,
    this.icon,
    this.description,
    this.color,
    this.type = 'switch',
    this.isCritical = false,
    this.activeTimerIds = const [],
    this.scheduleIds = const [],
    this.isUnderAutomation = false,
    this.lastManualChange,
  });

  // ============================================================================
  // التحويل من/إلى JSON
  // ============================================================================

  factory Relay.fromJson(Map<String, dynamic> json) {
    return Relay(
      id: json['id'] as int,
      name: json['name'] as String,
      pin: json['pin'] as int,
      state: json['state'] as bool,
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      color: json['color'] as String?,
      type: json['type'] as String? ?? 'switch',
      isCritical: json['isCritical'] as bool? ?? false,
      activeTimerIds: List<String>.from(json['activeTimerIds'] as List? ?? []),
      scheduleIds: List<String>.from(json['scheduleIds'] as List? ?? []),
      isUnderAutomation: json['isUnderAutomation'] as bool? ?? false,
      lastManualChange: json['lastManualChange'] != null
          ? DateTime.parse(json['lastManualChange'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pin': pin,
      'state': state,
      'icon': icon,
      'description': description,
      'color': color,
      'type': type,
      'isCritical': isCritical,
      'activeTimerIds': activeTimerIds,
      'scheduleIds': scheduleIds,
      'isUnderAutomation': isUnderAutomation,
      'lastManualChange': lastManualChange?.toIso8601String(),
    };
  }

  // ============================================================================
  // النسخ والتحديث
  // ============================================================================

  Relay copyWith({
    int? id,
    String? name,
    int? pin,
    bool? state,
    String? icon,
    String? description,
    String? color,
    String? type,
    bool? isCritical,
    List<String>? activeTimerIds,
    List<String>? scheduleIds,
    bool? isUnderAutomation,
    DateTime? lastManualChange,
  }) {
    return Relay(
      id: id ?? this.id,
      name: name ?? this.name,
      pin: pin ?? this.pin,
      state: state ?? this.state,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      color: color ?? this.color,
      type: type ?? this.type,
      isCritical: isCritical ?? this.isCritical,
      activeTimerIds: activeTimerIds ?? this.activeTimerIds,
      scheduleIds: scheduleIds ?? this.scheduleIds,
      isUnderAutomation: isUnderAutomation ?? this.isUnderAutomation,
      lastManualChange: lastManualChange ?? this.lastManualChange,
    );
  }

  /// تبديل حالة الروليه
  Relay toggle({bool updateAutomation = false}) => copyWith(
    state: !state,
    isUnderAutomation: updateAutomation,
    lastManualChange: DateTime.now(),
  );

  /// إضافة مؤقت
  Relay addTimer(String timerId) {
    if (activeTimerIds.contains(timerId)) return this;
    return copyWith(
      activeTimerIds: [...activeTimerIds, timerId],
      isUnderAutomation: true,
    );
  }

  /// إزالة مؤقت
  Relay removeTimer(String timerId) {
    final updated = activeTimerIds.where((id) => id != timerId).toList();
    return copyWith(
      activeTimerIds: updated,
      isUnderAutomation: updated.isNotEmpty || scheduleIds.isNotEmpty,
    );
  }

  /// إضافة جدولة
  Relay addSchedule(String scheduleId) {
    if (scheduleIds.contains(scheduleId)) return this;
    return copyWith(
      scheduleIds: [...scheduleIds, scheduleId],
      isUnderAutomation: true,
    );
  }

  /// إزالة جدولة
  Relay removeSchedule(String scheduleId) {
    final updated = scheduleIds.where((id) => id != scheduleId).toList();
    return copyWith(
      scheduleIds: updated,
      isUnderAutomation: updated.isNotEmpty || activeTimerIds.isNotEmpty,
    );
  }

  /// هل هناك مؤقت نشط؟
  bool get hasActiveTimers => activeTimerIds.isNotEmpty;

  /// هل هناك جدولة نشطة؟
  bool get hasSchedules => scheduleIds.isNotEmpty;

  @override
  String toString() => 'Relay(id: $id, name: $name, state: $state, '
      'timers: ${activeTimerIds.length}, schedules: ${scheduleIds.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Relay &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          state == other.state;

  @override
  int get hashCode => id.hashCode ^ state.hashCode;
}