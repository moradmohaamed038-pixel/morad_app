library;

import 'package:flutter/material.dart';
import 'dart:async';
import '../services/user_service.dart';
import '../models/user_model.dart';

/// إدارة حالة المستخدم
class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _userSubscription;

  // ============================================================================
  // Getters
  // ============================================================================

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  // ============================================================================
  // Load User
  // ============================================================================

  /// تحميل بيانات المستخدم الحالي
  Future<void> loadCurrentUser(String uid) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await _userService.getUser(uid);
      _currentUser = user;

      if (user != null) {
        print('✅ تم تحميل بيانات المستخدم');
        _watchUser(uid);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ خطأ: $e');
      _errorMessage = 'خطأ: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// المراقبة المباشرة لبيانات المستخدم
  void _watchUser(String uid) {
    _userSubscription?.cancel();
    _userSubscription = _userService.watchUser(uid).listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  // ============================================================================
  // User Operations
  // ============================================================================

  /// إنشاء مستخدم جديد
  Future<bool> createUser({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _userService.createUser(
        uid: uid,
        email: email,
        displayName: displayName,
      );

      if (user != null) {
        _currentUser = user;
        _errorMessage = null;
      }

      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _errorMessage = 'خطأ: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// تحديث بيانات المستخدم
  Future<bool> updateUser(Map<String, dynamic> updates) async {
    try {
      if (_currentUser == null) return false;

      _isLoading = true;
      notifyListeners();

      final success = await _userService.updateUser(
        _currentUser!.uid,
        updates,
      );

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

  // ============================================================================
  // Device Management
  // ============================================================================

  /// إضافة جهاز
  Future<bool> addDevice(String deviceId) async {
    try {
      if (_currentUser == null) return false;

      final success = await _userService.addDeviceToUser(
        _currentUser!.uid,
        deviceId,
      );

      return success;
    } catch (e) {
      _errorMessage = 'خطأ: $e';
      notifyListeners();
      return false;
    }
  }

  /// إزالة جهاز
  Future<bool> removeDevice(String deviceId) async {
    try {
      if (_currentUser == null) return false;

      final success = await _userService.removeDeviceFromUser(
        _currentUser!.uid,
        deviceId,
      );

      return success;
    } catch (e) {
      _errorMessage = 'خطأ: $e';
      notifyListeners();
      return false;
    }
  }

  /// الأجهزة
  List<String> get userDevices => _currentUser?.deviceIds ?? [];

  // ============================================================================
  // Cleanup
  // ============================================================================

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}