library;

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/user_model.dart';

/// خدمة إدارة بيانات المستخدم
class UserService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================================
  // CRUD Operations
  // ============================================================================

  /// حفظ بيانات المستخدم
  Future<bool> saveUser(UserModel user) async {
    try {
      print('💾 حفظ بيانات المستخدم: ${user.uid}');

      await _database.ref('users/${user.uid}').set(user.toJson());

      print('✅ تم حفظ بيانات المستخدم');
      return true;
    } catch (e) {
      print('❌ خطأ في الحفظ: $e');
      return false;
    }
  }

  /// جلب بيانات المستخدم
  Future<UserModel?> getUser(String uid) async {
    try {
      print('📖 جلب بيانات المستخدم: $uid');

      final snapshot = await _database.ref('users/$uid').get();

      if (!snapshot.exists) {
        print('❌ المستخدم غير موجود');
        return null;
      }

      final user = UserModel.fromJson(
        Map<String, dynamic>.from(snapshot.value as Map),
      );

      print('✅ تم جلب البيانات');
      return user;
    } catch (e) {
      print('❌ خطأ في الجلب: $e');
      return null;
    }
  }

  /// تحديث بيانات المستخدم
  Future<bool> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      print('✏️ تحديث المستخدم: $uid');

      updates['updatedAt'] = DateTime.now().toIso8601String();

      await _database.ref('users/$uid').update(updates);

      print('✅ تم التحديث');
      return true;
    } catch (e) {
      print('❌ خطأ في التحديث: $e');
      return false;
    }
  }

  /// حذف المستخدم
  Future<bool> deleteUser(String uid) async {
    try {
      print('🗑️ حذف المستخدم: $uid');

      await _database.ref('users/$uid').remove();

      print('✅ تم الحذف');
      return true;
    } catch (e) {
      print('❌ خطأ في الحذف: $e');
      return false;
    }
  }

  // ============================================================================
  // User Operations
  // ============================================================================

  /// الحصول على المستخدم الحالي
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      return getUser(currentUser.uid);
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  /// إنشاء مستخدم جديد
  Future<UserModel?> createUser({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    try {
      print('➕ إنشاء مستخدم جديد: $email');

      final user = UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
        role: 'user',
        deviceIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await saveUser(user);

      print('✅ تم إنشاء المستخدم');
      return user;
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  // ============================================================================
  // Device Management
  // ============================================================================

  /// إضافة جهاز للمستخدم
  Future<bool> addDeviceToUser(String uid, String deviceId) async {
    try {
      print('➕ إضافة جهاز للمستخدم: $deviceId');

      final user = await getUser(uid);
      if (user == null) return false;

      if (user.deviceIds.contains(deviceId)) {
        print('⚠️ الجهاز موجود بالفعل');
        return true;
      }

      final updatedDevices = [...user.deviceIds, deviceId];

      await updateUser(uid, {
        'deviceIds': updatedDevices,
      });

      print('✅ تم إضافة الجهاز');
      return true;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  /// إزالة جهاز من المستخدم
  Future<bool> removeDeviceFromUser(String uid, String deviceId) async {
    try {
      print('➖ إزالة جهاز من المستخدم: $deviceId');

      final user = await getUser(uid);
      if (user == null) return false;

      final updatedDevices = user.deviceIds
          .where((id) => id != deviceId)
          .toList();

      await updateUser(uid, {
        'deviceIds': updatedDevices,
      });

      print('✅ تم إزالة الجهاز');
      return true;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  /// الحصول على أجهزة المستخدم
  Future<List<String>> getUserDevices(String uid) async {
    try {
      final user = await getUser(uid);
      return user?.deviceIds ?? [];
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }

  // ============================================================================
  // Role Management
  // ============================================================================

  /// تحديث دور المستخدم
  Future<bool> updateUserRole(String uid, String newRole) async {
    try {
      print('🔐 تحديث دور المستخدم: $newRole');

      await updateUser(uid, {'role': newRole});

      print('✅ تم تحديث الدور');
      return true;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  // ============================================================================
  // Streams (للتحديثات المباشرة)
  // ============================================================================

  /// Stream لبيانات المستخدم
  Stream<UserModel?> watchUser(String uid) {
    return _database.ref('users/$uid').onValue.map((event) {
      if (!event.snapshot.exists) return null;
      try {
        return UserModel.fromJson(
          Map<String, dynamic>.from(event.snapshot.value as Map),
        );
      } catch (e) {
        print('❌ خطأ في تحليل البيانات: $e');
        return null;
      }
    });
  }

  /// Stream لأجهزة المستخدم
  Stream<List<String>> watchUserDevices(String uid) {
    return _database.ref('users/$uid/deviceIds').onValue.map((event) {
      if (!event.snapshot.exists) return [];
      try {
        return List<String>.from(event.snapshot.value as List);
      } catch (e) {
        print('❌ خطأ: $e');
        return [];
      }
    });
  }

  /// Stream لجميع المستخدمين (للمسؤولين)
  Stream<List<UserModel>> watchAllUsers() {
    return _database.ref('users').onValue.map((event) {
      if (!event.snapshot.exists) return [];
      try {
        final users = <UserModel>[];
        for (var child in event.snapshot.children) {
          users.add(UserModel.fromJson(
            Map<String, dynamic>.from(child.value as Map),
          ));
        }
        return users;
      } catch (e) {
        print('❌ خطأ: $e');
        return [];
      }
    });
  }

  // ============================================================================
  // Statistics
  // ============================================================================

  /// عدد المستخدمين
  Future<int> getUsersCount() async {
    try {
      final snapshot = await _database.ref('users').get();
      if (!snapshot.exists) return 0;
      return snapshot.children.length;
    } catch (e) {
      print('❌ خطأ: $e');
      return 0;
    }
  }

  /// المستخدمون النشطون (الذين قاموا بتسجيل دخول في آخر 7 أيام)
  Future<int> getActiveUsersCount() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _database.ref('users').get();

      if (!snapshot.exists) return 0;

      int count = 0;
      for (var child in snapshot.children) {
        final userData = Map<String, dynamic>.from(child.value as Map);
        final lastLogin = userData['lastLogin'];
        if (lastLogin != null) {
          final loginDate = DateTime.parse(lastLogin as String);
          if (loginDate.isAfter(sevenDaysAgo)) {
            count++;
          }
        }
      }

      return count;
    } catch (e) {
      print('❌ خطأ: $e');
      return 0;
    }
  }
}

/// نموذج المستخدم
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role; // owner, admin, user
  final List<String> deviceIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? photoUrl;
  final String? phoneNumber;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.deviceIds,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.phoneNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String? ?? 'user',
      deviceIds: List<String>.from(json['deviceIds'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      photoUrl: json['photoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'deviceIds': deviceIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
    };
  }
}