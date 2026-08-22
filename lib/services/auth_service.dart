library;

import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

/// خدمة المصادقة (Authentication)
/// تتحكم في:
/// - تسجيل الدخول
/// - إنشاء حسابات جديدة
/// - تسجيل الخروج
/// - إعادة تعيين كلمة المرور
/// - التحقق من المستخدم الحالي
class AuthService {
  // ============================================================================
  // مراجع Firebase
  // ============================================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================================
  // StreamControllers والبث
  // ============================================================================

  /// Stream لحالة المستخدم (متصل/غير متصل)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Stream لحالة اتصال المستخدم
  Stream<User?> get userChanges => _auth.userChanges();

  // ============================================================================
  // الخصائص
  // ============================================================================

  /// المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  /// هل المستخدم مسجل دخول؟
  bool get isLoggedIn => _auth.currentUser != null;

  /// معرّف المستخدم الحالي
  String? get currentUserId => _auth.currentUser?.uid;

  /// البريد الإلكتروني للمستخدم الحالي
  String? get currentUserEmail => _auth.currentUser?.email;

  /// اسم المستخدم الحالي
  String? get currentUserName => _auth.currentUser?.displayName;

  /// هل تم التحقق من البريد الإلكتروني؟
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ============================================================================
  // تسجيل الدخول
  // ============================================================================

  /// تسجيل دخول بالبريد الإلكتروني وكلمة المرور
  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 محاولة تسجيل الدخول: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('✅ تم تسجيل الدخول بنجاح: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ خطأ في تسجيل الدخول: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ خطأ غير متوقع: $e');
      throw 'خطأ غير متوقع: $e';
    }
  }

  /// تسجيل دخول مجهول (للتجربة)
  Future<UserCredential?> anonymousLogin() async {
    try {
      print('🔐 تسجيل دخول مجهول...');

      final userCredential = await _auth.signInAnonymously();

      print('✅ تم تسجيل الدخول مجهولاً');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ خطأ: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ خطأ غير متوقع: $e');
      throw 'خطأ غير متوقع: $e';
    }
  }

  // ============================================================================
  // إنشاء حسابات جديدة
  // ============================================================================

  /// إنشاء حساب جديد
  Future<UserCredential?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      print('📝 إنشاء حساب جديد: $email');

      // التحقق من القوة
      if (password.length < 6) {
        throw 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      }

      // إنشاء الحساب
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // تعيين اسم المستخدم
      await userCredential.user?.updateDisplayName(displayName);

      // إرسال بريد التحقق
      await sendEmailVerification();

      print('✅ تم إنشاء الحساب: $email');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ خطأ في الإنشاء: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ خطأ: $e');
      throw 'خطأ: $e';
    }
  }

  // ============================================================================
  // إدارة كلمات المرور
  // ============================================================================

  /// إرسال رابط إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email) async {
    try {
      print('📧 إرسال رابط إعادة التعيين: $email');

      await _auth.sendPasswordResetEmail(email: email.trim());

      print('✅ تم إرسال الرابط');
    } on FirebaseAuthException catch (e) {
      print('❌ خطأ: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ خطأ: $e');
      throw 'خطأ: $e';
    }
  }

  /// تغيير كلمة المرور
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      print('🔑 تغيير كلمة المرور...');

      if (newPassword.length < 6) {
        throw 'كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل';
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw 'لا يوجد مستخدم';
      }

      // إعادة مصادقة المستخدم أولاً
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // تغيير كلمة المرور
      await user.updatePassword(newPassword);

      print('✅ تم تغيير كلمة المرور');
    } on FirebaseAuthException catch (e) {
      print('❌ خطأ: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ خطأ: $e');
      throw 'خطأ: $e';
    }
  }

  // ============================================================================
  // التحقق من البريد الإلكتروني
  // ============================================================================

  /// إرسال بريد التحقق
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'لا يوجد مستخدم';
      }

      if (user.emailVerified) {
        print('✅ البريد مُتحقق منه بالفعل');
        return;
      }

      print('📧 إرسال بريد التحقق...');
      await user.sendEmailVerification();

      print('✅ تم إرسال بريد التحقق');
    } on FirebaseAuthException catch (e) {
      print('❌ خطأ: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ خطأ: $e');
      throw 'خطأ: $e';
    }
  }

  /// التحقق من حالة البريد
  Future<bool> checkEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // تحديث معلومات المستخدم
      await user.reload();

      return user.emailVerified;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  // ============================================================================
  // تحديث البيانات
  // ============================================================================

  /// تحديث اسم المستخدم
  Future<void> updateDisplayName(String newName) async {
    try {
      print('📝 تحديث الاسم: $newName');

      await _auth.currentUser?.updateDisplayName(newName);

      print('✅ تم تحديث الاسم');
    } on FirebaseAuthException catch (e) {
      print('❌ خطأ: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ خطأ: $e');
      throw 'خطأ: $e';
    }
  }

  /// تحديث صورة المستخدم
  Future<void> updatePhotoUrl(String photoUrl) async {
    try {
      print('📸 تحديث الصورة...');

      await _auth.currentUser?.updatePhotoURL(photoUrl);

      print('✅ تم تحديث الصورة');
    } on FirebaseAuthException catch (e) {
      print('❌ خطأ: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ خطأ: $e');
      throw 'خطأ: $e';
    }
  }

  // ============================================================================
  // تسجيل الخروج
  // ============================================================================

  /// تسجيل الخروج
  Future<void> logout() async {
    try {
      print('🚪 تسجيل الخروج...');

      await _auth.signOut();

      print('✅ تم تسجيل الخروج');
    } catch (e) {
      print('❌ خطأ: $e');
      throw 'خطأ: $e';
    }
  }

  /// حذف الحساب
  Future<void> deleteAccount({required String password}) async {
    try {
      print('🗑️ حذف الحساب...');

      final user = _auth.currentUser;
      if (user == null) {
        throw 'لا يوجد مستخدم';
      }

      // إعادة مصادقة أولاً
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      // حذف الحساب
      await user.delete();

      print('✅ تم حذف الحساب');
    } on FirebaseAuthException catch (e) {
      print('❌ خطأ: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ خطأ: $e');
      throw 'خطأ: $e';
    }
  }

  // ============================================================================
  // معالجة الأخطاء
  // ============================================================================

  /// معالجة استثناءات Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'المستخدم غير موجود';
      case 'wrong-password':
        return 'كلمة المرور خاطئة';
      case 'email-already-in-use':
        return 'البريد مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'invalid-email':
        return 'البريد غير صحيح';
      case 'operation-not-allowed':
        return 'هذه العملية غير مسموحة';
      case 'too-many-requests':
        return 'محاولات كثيرة جداً، حاول لاحقاً';
      case 'network-request-failed':
        return 'خطأ في الإنترنت';
      default:
        return 'خطأ: ${e.message}';
    }
  }

  // ============================================================================
  // معلومات المستخدم
  // ============================================================================

  /// الحصول على معلومات المستخدم الحالي
  Map<String, dynamic>? getCurrentUserInfo() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'emailVerified': user.emailVerified,
      'isAnonymous': user.isAnonymous,
      'createdTime': user.metadata.creationTime,
      'lastSignIn': user.metadata.lastSignInTime,
    };
  }

  /// تحديث معلومات المستخدم من Firebase
  Future<void> refreshUserInfo() async {
    try {
      await _auth.currentUser?.reload();
      print('✅ تم تحديث معلومات المستخدم');
    } catch (e) {
      print('❌ خطأ: $e');
    }
  }
}