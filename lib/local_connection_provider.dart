library;

import 'package:flutter/material.dart';
import 'dart:async';
import '../models/relay_model.dart';
import '../models/sensor_model.dart';
import '../services/local_connection_service.dart';

/// إدارة الاتصال المحلي مع ESP32
/// يتحكم في:
/// - حالة الاتصال
/// - استقبال التحديثات الحية
/// - إرسال الأوامر
class LocalConnectionProvider extends ChangeNotifier {
  // ============================================================================
  // المتغيرات الخاصة
  // ============================================================================

  /// خدمة الاتصال المحلي
  late LocalConnectionService _connectionService;

  /// حالة الاتصال
  bool _isConnected = false;

  /// رسالة الخطأ
  String? _errorMessage;

  /// آخر رسالة تم استقبالها
  Map<String, dynamic>? _lastMessage;

  /// الروليهات المحدثة
  Map<int, Relay> _updatedRelays = {};

  /// الحساسات المحدثة
  Map<int, Sensor> _updatedSensors = {};

  /// وقت آخر اتصال نجح
  DateTime? _lastSuccessfulConnection;

  /// عدد محاولات الاتصال الفاشلة
  int _failedConnectionAttempts = 0;

  /// Stream subscriptions
  StreamSubscription? _relayUpdatesSubscription;
  StreamSubscription? _sensorUpdatesSubscription;
  StreamSubscription? _messagesSubscription;

  // ============================================================================
  // Getters
  // ============================================================================

  bool get isConnected => _isConnected;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get lastMessage => _lastMessage;
  Map<int, Relay> get updatedRelays => Map.unmodifiable(_updatedRelays);
  Map<int, Sensor> get updatedSensors => Map.unmodifiable(_updatedSensors);
  DateTime? get lastSuccessfulConnection => _lastSuccessfulConnection;
  int get failedConnectionAttempts => _failedConnectionAttempts;

  // ============================================================================
  // التهيئة
  // ============================================================================

  LocalConnectionProvider() {
    _connectionService = LocalConnectionService();
    print('✅ تم تهيئة Local Connection Provider');
  }

  // ============================================================================
  // الاتصال والمصادقة
  // ============================================================================

  /// الاتصال بجهاز ESP32
  Future<bool> connect({
    required String ipAddress,
    required int port,
    required String password,
  }) async {
    try {
      print('🔌 بدء الاتصال...');

      _isConnected = false;
      _errorMessage = null;
      _failedConnectionAttempts = 0;
      notifyListeners();

      // محاولة الاتصال
      final connected = await _connectionService.connect(
        ipAddress: ipAddress,
        port: port,
        password: password,
      );

      if (connected) {
        _isConnected = true;
        _lastSuccessfulConnection = DateTime.now();
        _errorMessage = null;

        // بدء الاستماع للتحديثات
        _startListening();

        print('✅ متصل بنجاح!');
      } else {
        _isConnected = false;
        _errorMessage = 'فشلت المصادقة';
        _failedConnectionAttempts++;
        print('❌ فشلت المصادقة');
      }

      notifyListeners();
      return connected;
    } catch (e) {
      print('❌ خطأ في الاتصال: $e');
      _isConnected = false;
      _errorMessage = 'خطأ: $e';
      _failedConnectionAttempts++;
      notifyListeners();
      return false;
    }
  }

  /// قطع الاتصال
  Future<void> disconnect() async {
    try {
      print('🔌 قطع الاتصال...');

      await _relayUpdatesSubscription?.cancel();
      await _sensorUpdatesSubscription?.cancel();
      await _messagesSubscription?.cancel();

      await _connectionService.disconnect();

      _isConnected = false;
      _errorMessage = null;

      print('✅ تم قطع الاتصال');
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في قطع الاتصال: $e');
      _errorMessage = 'خطأ: $e';
      notifyListeners();
    }
  }

  /// إعادة محاولة الاتصال
  Future<bool> reconnect({
    required String ipAddress,
    required int port,
    required String password,
  }) async {
    await disconnect();
    await Future.delayed(const Duration(seconds: 1));
    return connect(
      ipAddress: ipAddress,
      port: port,
      password: password,
    );
  }

  // ============================================================================
  // الاستماع للتحديثات
  // ============================================================================

  /// بدء الاستماع للرسائل الواردة
  void _startListening() {
    // الاستماع لتحديثات الروليهات
    _relayUpdatesSubscription = _connectionService.relayUpdates.listen(
      (relay) {
        _updatedRelays[relay.id] = relay;
        print('📤 تحديث روليه: ${relay.name} = ${relay.state}');
        notifyListeners();
      },
      onError: (error) {
        print('❌ خطأ في تحديثات الروليهات: $error');
        _handleConnectionError(error);
      },
    );

    // الاستماع لتحديثات الحساسات
    _sensorUpdatesSubscription = _connectionService.sensorUpdates.listen(
      (data) {
        final sensorId = data['sensor_id'] as int?;
        if (sensorId != null) {
          final value = (data['value'] as num?)?.toDouble() ?? 0;
          print('📊 تحديث حساس: $sensorId = $value');
        }
        notifyListeners();
      },
      onError: (error) {
        print('❌ خطأ في تحديثات الحساسات: $error');
        _handleConnectionError(error);
      },
    );

    // الاستماع لجميع الرسائل
    _messagesSubscription = _connectionService.messages.listen(
      (message) {
        _lastMessage = message;
        print('📨 رسالة جديدة: $message');
      },
      onError: (error) {
        print('❌ خطأ في الرسائل: $error');
        _handleConnectionError(error);
      },
    );
  }

  /// معالجة أخطاء الاتصال
  void _handleConnectionError(Object error) {
    _isConnected = false;
    _errorMessage = 'فُقد الاتصال: $error';
    _failedConnectionAttempts++;
    notifyListeners();
  }

  // ============================================================================
  // أوامر الروليهات
  // ============================================================================

  /// تبديل حالة روليه
  Future<bool> toggleRelay({
    required int relayId,
    required bool newState,
  }) async {
    try {
      if (!_isConnected) {
        _errorMessage = 'الجهاز غير متصل';
        notifyListeners();
        return false;
      }

      print('⚡ تبديل الروليه $relayId إلى $newState');

      final success = await _connectionService.toggleRelay(
        relayId: relayId,
        newState: newState,
      );

      if (success) {
        _errorMessage = null;
      } else {
        _errorMessage = 'فشل الأمر';
      }

      notifyListeners();
      return success;
    } catch (e) {
      print('❌ خطأ: $e');
      _errorMessage = 'خطأ: $e';
      notifyListeners();
      return false;
    }
  }

  /// تشغيل روليه بمؤقت
  Future<bool> toggleRelayWithTimer({
    required int relayId,
    required int durationSeconds,
  }) async {
    try {
      if (!_isConnected) {
        _errorMessage = 'الجهاز غير متصل';
        notifyListeners();
        return false;
      }

      print('⏱️ تشغيل الروليه $relayId لمدة $durationSeconds ثانية');

      final success = await _connectionService.toggleRelayWithTimer(
        relayId: relayId,
        durationSeconds: durationSeconds,
      );

      if (success) {
        _errorMessage = null;
      } else {
        _errorMessage = 'فشل تشغيل المؤقت';
      }

      notifyListeners();
      return success;
    } catch (e) {
      print('❌ خطأ: $e');
      _errorMessage = 'خطأ: $e';
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // جلب البيانات
  // ============================================================================

  /// جلب حالة جميع الروليهات
  Future<List<Relay>?> getRelaysStatus() async {
    try {
      if (!_isConnected) {
        return null;
      }

      print('🔄 جلب حالة الروليهات...');

      final relays = await _connectionService.getRelaysStatus();

      if (relays != null) {
        for (var relay in relays) {
          _updatedRelays[relay.id] = relay;
        }
        _errorMessage = null;
        notifyListeners();
      }

      return relays;
    } catch (e) {
      print('❌ خطأ: $e');
      _errorMessage = 'خطأ: $e';
      notifyListeners();
      return null;
    }
  }

  // ============================================================================
  // الإحصائيات
  // ============================================================================

  /// عدد الروليهات المحدثة
  int get updatedRelaysCount => _updatedRelays.length;

  /// عدد الحساسات المحدثة
  int get updatedSensorsCount => _updatedSensors.length;

  /// وقت الاتصال (بالثواني)
  int? get connectionDurationSeconds {
    if (_lastSuccessfulConnection == null) return null;
    return DateTime.now().difference(_lastSuccessfulConnection!).inSeconds;
  }

  // ============================================================================
  // التنظيف
  // ============================================================================

  @override
  Future<void> dispose() async {
    await disconnect();
    await _connectionService.dispose();
    super.dispose();
  }
}