library;

import 'package:flutter/material.dart';
import 'dart:async';
import '../services/notifications_service.dart';
import '../models/notification_model.dart';

/// إدارة الإشعارات
class NotificationsProvider extends ChangeNotifier {
  final NotificationsService _notificationsService = NotificationsService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _notificationsSubscription;
  String? _currentUserId;

  // ============================================================================
  // Getters
  // ============================================================================

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  int get unreadCount => unreadNotifications.length;

  // ============================================================================
  // Initialize
  // ============================================================================

  /// بدء المراقبة
  void startWatching(String userId) {
    _currentUserId = userId;
    _notificationsSubscription?.cancel();

    _notificationsSubscription =
        _notificationsService.watchNotifications(userId).listen((notifications) {
      _notifications = notifications;
      notifyListeners();
    });
  }

  /// إيقاف المراقبة
  void stopWatching() {
    _notificationsSubscription?.cancel();
  }

  // ============================================================================
  // CRUD Operations
  // ============================================================================

  /// إنشاء إشعار
  Future<bool> createNotification({
    required String title,
    required String message,
    required String type,
    String? deviceId,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (_currentUserId == null) return false;

      _isLoading = true;
      notifyListeners();

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _currentUserId!,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deviceId: deviceId,
        data: data,
      );

      final success =
          await _notificationsService.createNotification(notification);

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'خطأ: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// وضع علامة كمقروء
  Future<bool> markAsRead(String notificationId) async {
    try {
      if (_currentUserId == null) return false;

      return await _notificationsService.markAsRead(
        _currentUserId!,
        notificationId,
      );
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  /// وضع علامة على الكل كمقروء
  Future<bool> markAllAsRead() async {
    try {
      if (_currentUserId == null) return false;

      return await _notificationsService.markAllAsRead(_currentUserId!);
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  /// حذف إشعار
  Future<bool> deleteNotification(String notificationId) async {
    try {
      if (_currentUserId == null) return false;

      return await _notificationsService.deleteNotification(
        _currentUserId!,
        notificationId,
      );
    } catch (e) {
      _errorMessage = 'خطأ: $e';
      notifyListeners();
      return false;
    }
  }

  /// حذف الكل
  Future<bool> deleteAll() async {
    try {
      if (_currentUserId == null) return false;

      return await _notificationsService.deleteAllNotifications(_currentUserId!);
    } catch (e) {
      _errorMessage = 'خطأ: $e';
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // Cleanup
  // ============================================================================

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }
}