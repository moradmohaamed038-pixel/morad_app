library;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

/// خدمة تهيئة Firebase بشكل آمن وموثوق
class FirebaseInitService {
  static bool _initialized = false;
  static late FirebaseDatabase _database;

  static bool get isInitialized => _initialized;
  static FirebaseDatabase get database => _database;

  /// تهيئة Firebase - تشغيل مرة واحدة فقط
  static Future<void> initialize() async {
    if (_initialized) {
      print('✅ Firebase مهيأ بالفعل');
      return;
    }

    try {
      print('🔥 بدء تهيئة Firebase...');

      // تهيئة Firebase Core
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // تهيئة Realtime Database
      _database = FirebaseDatabase.instance;

      // تعيين رابط قاعدة البيانات
      _database.databaseURL =
          'https://morad-tk-default-rtdb.europe-west1.firebasedatabase.app';

      _initialized = true;
      print('✅ Firebase هيئت بنجاح!');

      // تحقق من الاتصال
      await _verifyConnection();
    } catch (e) {
      print('❌ خطأ في تهيئة Firebase: $e');
      rethrow;
    }
  }

  /// التحقق من الاتصال بـ Firebase
  static Future<void> _verifyConnection() async {
    try {
      print('🔍 التحقق من اتصال Firebase...');

      // كتابة بيانات اختبار
      await _database.ref('health_check').set({
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'connected',
        'app_version': '2.0.0',
      }).timeout(
        const Duration(seconds: 10),
      );

      print('✅ الاتصال بـ Firebase نجح!');
    } catch (e) {
      print('⚠️ تحذير: قد يكون الاتصال بطيئاً: $e');
    }
  }

  /// الحصول على مرجع قاعدة البيانات
  static DatabaseReference getRef(String path) {
    return _database.ref(path);
  }
}