library;

import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../models/notification_model.dart';

/// خدمة الإشعارات
class NotificationsService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // ============================================================================
  // CRUD Operations
  // ============================================================================

  /// إنشاء إشعار جديد
  Future<bool> createNotification(NotificationModel notification) async {
    try {
      print('📝 إنشاء إشعار جديد: ${notification.id}');

      await _database
          .ref('notifications/${notification.userId}/${notification.id}')
          .set(notification.toJson());

      print('✅ تم إنشاء الإشعار');
      return true;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  /// جلب إشعار
  Future<NotificationModel?> getNotification(
    String userId,
    String notificationId,
  ) async {
    try {
      final snapshot = await _database
          .ref('notifications/$userId/$notificationId')
          .get();

      if (!snapshot.exists) return null;

      return NotificationModel.fromJson(
        Map<String, dynamic>.from(snapshot.value as Map),
      );
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  /// تحديث الإشعار
  Future<bool> updateNotification(
    String userId,
    String notificationId,
    Map<String, dynamic> updates,
  ) async {
    try {
      print('✏️ تحديث الإشعار: $notificationId');

      updates['updatedAt'] = DateTime.now().toIso8601String();

      await _database
          .ref('notifications/$userId/$notificationId')
          .update(updates);

      print('✅ تم التحديث');
      return true;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  /// حذف الإشعار
  Future<bool> deleteNotification(
    String userId,
    String notificationId,
  ) async {
    try {
      print('🗑️ حذف الإشعار: $notificationId');

      await _database.ref('notifications/$userId/$notificationId').remove();

      print('✅ تم الحذف');
      return true;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  /// حذف جميع الإشعارات
  Future<bool> deleteAllNotifications(String userId) async {
    try {
      print('🗑️ حذف جميع الإشعارات');

      await _database.ref('notifications/$userId').remove();

      print('✅ تم الحذف');
      return true;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  // ============================================================================
  // Query Operations
  // ============================================================================

  /// جلب جميع الإشعارات
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      print('📖 جلب الإشعارات...');

      final snapshot = await _database.ref('notifications/$userId').get();

      if (!snapshot.exists) return [];

      final notifications = <NotificationModel>[];
      for (var child in snapshot.children) {
        notifications.add(NotificationModel.fromJson(
          Map<String, dynamic>.from(child.value as Map),
        ));
      }

      // ترتيب حسب الوقت (الأحدث أولاً)
      notifications
          .sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ تم جلب ${notifications.length} إشعار');
      return notifications;
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }

  /// جلب الإشعارات غير المقروءة
  Future<List<NotificationModel>> getUnreadNotifications(
    String userId,
  ) async {
    try {
      final notifications = await getNotifications(userId);
      return notifications.where((n) => !n.isRead).toList();
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }

  /// جلب الإشعارات حسب النوع
  Future<List<NotificationModel>> getNotificationsByType(
    String userId,
    String type,
  ) async {
    try {
      final notifications = await getNotifications(userId);
      return notifications.where((n) => n.type == type).toList();
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }

  // ============================================================================
  // Actions
  // ============================================================================

  /// وضع علامة على الإشعار كمقروء
  Future<bool> markAsRead(String userId, String notificationId) async {
    return updateNotification(userId, notificationId, {'isRead': true});
  }

  /// وضع علامة على جميع الإشعارات كمقروءة
  Future<bool> markAllAsRead(String userId) async {
    try {
      print('✓ وضع علامة على الكل كمقروء');

      final notifications = await getNotifications(userId);

      for (var notification in notifications) {
        if (!notification.isRead) {
          await markAsRead(userId, notification.id);
        }
      }

      print('✅ تم وضع العلامات');
      return true;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  // ============================================================================
  // Streams
  // ============================================================================

  /// Stream لجميع الإشعارات
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _database.ref('notifications/$userId').onValue.map((event) {
      if (!event.snapshot.exists) return [];
      try {
        final notifications = <NotificationModel>[];
        for (var child in event.snapshot.children) {
          notifications.add(NotificationModel.fromJson(
            Map<String, dynamic>.from(child.value as Map),
          ));
        }
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return notifications;
      } catch (e) {
        print('❌ خطأ: $e');
        return [];
      }
    });
  }

  /// Stream للإشعارات غير المقروءة
  Stream<List<NotificationModel>> watchUnreadNotifications(String userId) {
    return watchNotifications(userId).map((notifications) =>
        notifications.where((n) => !n.isRead).toList());
  }

  // ============================================================================
  // Statistics
  // ============================================================================

  /// عدد الإشعارات غير المقروءة
  Future<int> getUnreadCount(String userId) async {
    try {
      final unread = await getUnreadNotifications(userId);
      return unread.length;
    } catch (e) {
      print('❌ خطأ: $e');
      return 0;
    }
  }

  /// إجمالي الإشعارات
  Future<int> getTotalCount(String userId) async {
    try {
      final notifications = await getNotifications(userId);
      return notifications.length;
    } catch (e) {
      print('❌ خطأ: $e');
      return 0;
    }
  }
}

/// نموذج الإشعار
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // device, command, alert, system
  final String? deviceId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.deviceId,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String? ?? 'system',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deviceId: json['deviceId'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deviceId': deviceId,
      'data': data,
    };
  }
}