library;

import 'package:flutter/material.dart';
import 'dart:async';
import '../services/analytics_service.dart';
import '../models/analytics_model.dart';

/// إدارة الإحصائيات
class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();

  Map<String, AnalyticsModel> _deviceAnalytics = {};
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, StreamSubscription> _subscriptions = {};

  // ============================================================================
  // Getters
  // ============================================================================

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AnalyticsModel? getDeviceAnalytics(String deviceId) =>
      _deviceAnalytics[deviceId];

  // ============================================================================
  // Watch Analytics
  // ============================================================================

  /// مراقبة إحصائيات جهاز
  void watchDeviceAnalytics(String deviceId) {
    _subscriptions[deviceId]?.cancel();

    _subscriptions[deviceId] =
        _analyticsService.watchAnalytics(deviceId).listen((analytics) {
      if (analytics != null) {
        _deviceAnalytics[deviceId] = analytics;
        notifyListeners();
      }
    });
  }

  /// إيقاف المراقبة
  void stopWatching(String deviceId) {
    _subscriptions[deviceId]?.cancel();
    _subscriptions.remove(deviceId);
  }

  /// إيقاف كل المراقبات
  void stopAllWatching() {
    for (var subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  // ============================================================================
  // Record Commands
  // ============================================================================

  /// تسجيل أمر
  Future<bool> recordCommand({
    required String deviceId,
    required int relayId,
    required bool action,
    required bool success,
  }) async {
    try {
      return await _analyticsService.recordCommand(
        deviceId: deviceId,
        relayId: relayId,
        action: action,
        success: success,
      );
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  // ============================================================================
  // Uptime Tracking
  // ============================================================================

  /// بدء التتبع
  Future<bool> startUptimeTracking(String deviceId) async {
    try {
      return await _analyticsService.startUptimeTracking(deviceId);
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  /// إيقاف التتبع
  Future<bool> stopUptimeTracking(String deviceId) async {
    try {
      return await _analyticsService.stopUptimeTracking(deviceId);
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  // ============================================================================
  // Statistics
  // ============================================================================

  /// إحصائيات اليوم
  Future<Map<String, dynamic>> getTodayStats(String deviceId) async {
    try {
      return await _analyticsService.getTodayStats(deviceId);
    } catch (e) {
      print('❌ خطأ: $e');
      return {};
    }
  }

  // ============================================================================
  // Cleanup
  // ============================================================================

  @override
  void dispose() {
    stopAllWatching();
    super.dispose();
  }
}