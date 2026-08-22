library;

import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';

/// إدارة حالة المصادقة
/// يجمع بين FirebaseAuth والـ UI Logic
class AuthProvider extends ChangeNotifier {
  // ============================================================================
  // المتغيرات الخاصة
  // ============================================================================

  final AuthService _authService = AuthService();

  /// هل المستخدم مسجل دخول؟
  bool _isLoggedIn = false;

  /// هل يتم تحميل البيانات؟
  bool _isLoading = false;

  /// رسالة الخطأ
  String? _errorMessage;

  /// معرّف المستخدم
  String? _userId;

  /// بريد المستخدم
  String? _userEmail;

  /// اسم المستخدم
  String? _userName;

  /// صورة المستخدم
  String? _userPhotoUrl;

  /// هل تم التحقق من البريد؟
  bool _emailVerified = false;

  /// Subscription لمراقبة حالة المصادقة
  StreamSubscription? _authSubscription;

  // ============================================================================
  // Getters
  // ============================================================================

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userPhotoUrl => _userPhotoUrl;
  bool get emailVerified => _emailVerified;

  // ============================================================================
  // التهيئة
  // ============================================================================

  /// بناء Provider
  AuthProvider() {
    _initializeAuthListener();
  }

  /// بدء الاستماع لتغييرات المصادقة
  void _initializeAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        _isLoggedIn = true;
        _userId = user.uid;
        _userEmail = user.email;
        _userName = user.displayName;
        _userPhotoUrl = user.photoURL;
        _emailVerified = user.emailVerified;
        print('✅ مستخدم مسجل دخول: $userEmail');
      } else {
        _isLoggedIn = false;
        _userId = null;
        _userEmail = null;
        _userName = null;
        _userPhotoUrl = null;
        _emailVerified = false;
        print('🚪 مستخدم غير مسجل دخول');
      }
      _errorMessage = null;
      notifyListeners();
    });
  }

  // ============================================================================
  // تسجيل الدخول
  // ============================================================================

  /// تسجيل دخول
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.login(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// تسجيل دخول مجهول
  Future<bool> anonymousLogin() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.anonymousLogin();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // التسجيل
  // ============================================================================

  /// إنشاء حساب جديد
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
      );

      _isLoading = false;
      _errorMessage = 'تم الإنشاء بنجاح! تحقق من بريدك';
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // إدارة كلمات المرور
  // ============================================================================

  /// إرسال رابط إعادة التعيين
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.resetPassword(email);

      _isLoading = false;
      _errorMessage = 'تم إرسال الرابط';
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// تغيير كلمة المرور
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _isLoading = false;
      _errorMessage = 'تم التغيير بنجاح';
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // تسجيل الخروج
  // ============================================================================

  /// تسجيل الخروج
  Future<bool> logout() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.logout();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// حذف الحساب
  Future<bool> deleteAccount({required String password}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.deleteAccount(password: password);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // البريد الإلكتروني
  // ============================================================================

  /// إرسال بريد التحقق
  Future<bool> sendEmailVerification() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.sendEmailVerification();

      _isLoading = false;
      _errorMessage = 'تم إرسال بريد التحقق';
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// التحقق من حالة البريد
  Future<bool> checkEmailVerified() async {
    try {
      final verified = await _authService.checkEmailVerified();
      _emailVerified = verified;
      notifyListeners();
      return verified;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  // ============================================================================
  // تحديث البيانات
  // ============================================================================

  /// تحديث اسم المستخدم
  Future<bool> updateDisplayName(String newName) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.updateDisplayName(newName);

      _userName = newName;
      _isLoading = false;
      _errorMessage = 'تم التحديث بنجاح';
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // التنظيف
  // ============================================================================

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}