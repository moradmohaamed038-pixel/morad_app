library;

/// نموذج المؤقت (Timer) للروليه
/// يسمح بتشغيل/إيقاف الروليه بعد فترة محددة
class RelayTimer {
  /// معرّف المؤقت (فريد)
  final String id;

  /// معرّف الروليه الذي ينطبق عليه
  final int relayId;

  /// معرّف اللوحة
  final String deviceId;

  /// الحالة المطلوبة (true = تشغيل، false = إيقاف)
  final bool targetState;

  /// المدة بالدقائق
  /// مثال: 5 = بعد 5 دقائق
  final int durationMinutes;

  /// الحالة الحالية للمؤقت
  /// "active" = جاري التعداد
  /// "paused" = موقوف مؤقتاً
  /// "completed" = انتهى
  /// "cancelled" = ملغى
  final String status;

  /// الوقت الذي تم بدء المؤقت فيه
  final DateTime startTime;

  /// الوقت المتبقي (ثوان)
  int? remainingSeconds;

  RelayTimer({
    required this.id,
    required this.relayId,
    required this.deviceId,
    required this.targetState,
    required this.durationMinutes,
    this.status = 'active',
    DateTime? startTime,
    this.remainingSeconds,
  }) : startTime = startTime ?? DateTime.now();

  // ============================================================================
  // التحويل من/إلى JSON
  // ============================================================================

  factory RelayTimer.fromJson(Map<String, dynamic> json) {
    return RelayTimer(
      id: json['id'] as String,
      relayId: json['relayId'] as int,
      deviceId: json['deviceId'] as String,
      targetState: json['targetState'] as bool,
      durationMinutes: json['durationMinutes'] as int,
      status: json['status'] as String? ?? 'active',
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      remainingSeconds: json['remainingSeconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relayId': relayId,
      'deviceId': deviceId,
      'targetState': targetState,
      'durationMinutes': durationMinutes,
      'status': status,
      'startTime': startTime.toIso8601String(),
      'remainingSeconds': remainingSeconds,
    };
  }

  // ============================================================================
  // الدوال المساعدة
  // ============================================================================

  /// الوقت المتبقي بصيغة نصية (مثل: "05:30")
  String get timeDisplay {
    if (remainingSeconds == null) return 'N/A';
    final minutes = remainingSeconds! ~/ 60;
    final seconds = remainingSeconds! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// هل المؤقت انتهى؟
  bool get isExpired => status == 'completed' || status == 'cancelled';

  /// هل المؤقت جاري؟
  bool get isActive => status == 'active';

  /// النسبة المئوية للمؤقت (للرسوم البيانية)
  double get percentage {
    final totalSeconds = durationMinutes * 60;
    if (remainingSeconds == null) return 0;
    return ((totalSeconds - remainingSeconds!) / totalSeconds) * 100;
  }

  @override
  String toString() => 'RelayTimer(relayId: $relayId, remaining: $timeDisplay)';
}