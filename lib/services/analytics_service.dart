library;

import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../models/analytics_model.dart';

/// خدمة الإحصائيات
class AnalyticsService {
    final FirebaseDatabase _database = FirebaseDatabase.instance;




  // ============================================================================
  // Command Recording
  // ============================================================================

  /// تسجيل أمر
  Future<bool> recordCommand({
    required String deviceId,
    required int relayId,
    required bool action,
    required bool success,
  }) async {
    try {
      print('📝 تسجيل أمر: $deviceId -> $relayId');

      final timestamp = DateTime.now();
      final commandKey = _database.ref('analytics/$deviceId/commands').push().key;

      if (commandKey == null) return false;

      await _database
          .ref('analytics/$deviceId/commands/$commandKey')
          .set({
            'relayId': relayId,
            'action': action,
            'success': success,
            'timestamp': timestamp.toIso8601String(),
          });

      // تحديث الإحصائيات
      await _updateStats(deviceId, success);

      print('✅ تم التسجيل');
      return true;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  /// تحديث الإحصائيات
  Future<void> _updateStats(String deviceId, bool success) async {
    try {
      await _database.ref('analytics/$deviceId').update({
        'totalCommands': ServerValue.increment(1),
        'successfulCommands': success ? ServerValue.increment(1) : 0,
        'lastUpdate': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ خطأ في التحديث: $e');
    }
  }

  // ============================================================================
  // Uptime Tracking
  // ============================================================================

  /// بدء تتبع التشغيل
  Future<bool> startUptimeTracking(String deviceId) async {
    try {
      print('⏱️ بدء تتبع التشغيل: $deviceId');

      await _database.ref('analytics/$deviceId').update({
        'startTime': DateTime.now().toIso8601String(),
        'isOnline': true,
      });

      print('✅ تم البدء');
      return true;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  /// إيقاف تتبع التشغيل
  Future<bool> stopUptimeTracking(String deviceId) async {
    try {
      print('⏱️ إيقاف تتبع التشغيل: $deviceId');

      await _database.ref('analytics/$deviceId').update({
        'endTime': DateTime.now().toIso8601String(),
        'isOnline': false,
      });

      print('✅ تم الإيقاف');
      return true;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  // ============================================================================
  // Statistics Query
  // ============================================================================

  /// جلب إحصائيات جهاز
  Future<AnalyticsModel?> getDeviceAnalytics(String deviceId) async {
    try {
      print('📊 جلب الإحصائيات: $deviceId');

      final snapshot = await _database.ref('analytics/$deviceId').get();

      if (!snapshot.exists) {
        print('❌ لا توجد بيانات');
        return null;
      }

      return AnalyticsModel.fromJson(
        Map<String, dynamic>.from(snapshot.value as Map),
      );
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  /// جلب الأوامر
  Future<List<Map<String, dynamic>>> getCommands(String deviceId) async {
    try {
      final snapshot =
          await _database.ref('analytics/$deviceId/commands').get();

      if (!snapshot.exists) return [];

      final commands = <Map<String, dynamic>>[];
      for (var child in snapshot.children) {
        commands.add(Map<String, dynamic>.from(child.value as Map));
      }

      return commands;
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }

  /// إحصائيات اليوم
  Future<Map<String, dynamic>> getTodayStats(String deviceId) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final commands = await getCommands(deviceId);

      final todayCommands = commands.where((cmd) {
        final timestamp = DateTime.parse(cmd['timestamp'] as String);
        return timestamp.isAfter(todayStart) &&
            timestamp.isBefore(now);
      }).toList();

      return {
        'totalCommands': todayCommands.length,
        'successfulCommands':
            todayCommands.where((cmd) => cmd['success'] == true).length,
        'date': todayStart.toIso8601String(),
      };
    } catch (e) {
      print('❌ خطأ: $e');
      return {};
    }
  }

  // ============================================================================
  // Streams
  // ============================================================================

  /// Stream للإحصائيات
  Stream<AnalyticsModel?> watchAnalytics(String deviceId) {
    return _database.ref('analytics/$deviceId').onValue.map((event) {
      if (!event.snapshot.exists) return null;
      try {
        return AnalyticsModel.fromJson(
          Map<String, dynamic>.from(event.snapshot.value as Map),
        );
      } catch (e) {
        print('❌ خطأ: $e');
        return null;
      }
    });
  }

  /// Stream للأوامر
  Stream<List<Map<String, dynamic>>> watchCommands(String deviceId) {
    return _database.ref('analytics/$deviceId/commands').onValue.map((event) {
      if (!event.snapshot.exists) return [];
      try {
        final commands = <Map<String, dynamic>>[];
        for (var child in event.snapshot.children) {
          commands.add(Map<String, dynamic>.from(child.value as Map));
        }
        return commands;
      } catch (e) {
        print('❌ خطأ: $e');
        return [];
      }
    });
  }
}

/// نموذج الإحصائيات
class AnalyticsModel {
  final String deviceId;
  final int totalCommands;
  final int successfulCommands;
  final double successRate;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isOnline;
  final DateTime lastUpdate;

  AnalyticsModel({
    required this.deviceId,
    required this.totalCommands,
    required this.successfulCommands,
    required this.successRate,
    required this.isOnline,
    required this.lastUpdate,
    this.startTime,
    this.endTime,
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    final total = (json['totalCommands'] as num?)?.toInt() ?? 0;
    final successful = (json['successfulCommands'] as num?)?.toInt() ?? 0;
    final rate = total > 0 ? (successful / total) * 100 : 0.0;

    return AnalyticsModel(
      deviceId: json['deviceId'] as String? ?? '',
      totalCommands: total,
      successfulCommands: successful,
      successRate: rate,
      isOnline: json['isOnline'] as bool? ?? false,
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.parse(json['lastUpdate'] as String)
          : DateTime.now(),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'totalCommands': totalCommands,
      'successfulCommands': successfulCommands,
      'successRate': successRate,
      'isOnline': isOnline,
      'lastUpdate': lastUpdate.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }
}
