library;

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:async';
import 'dart:convert';
import 'esp_device_model.dart';
import 'relay_model.dart';

/// خدمة الاتصال المحلي مع ESP32
/// تستخدم WebSocket للتواصل الفوري
class LocalConnectionService {
  // الاتصال الحالي
  WebSocketChannel? _channel;

  // معرّف الجهاز المتصل
  String? _connectedDeviceId;

  // Stream للرسائل الواردة
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  // حالة الاتصال
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // ============================================================================
  // الاتصال والمصادقة
  // ============================================================================

  /// الاتصال بجهاز ESP32
  /// يتطلب عنوان IP وكلمة المرور
  Future<bool> connect({
    required String ipAddress,
    required int port,
    required String password,
  }) async {
    try {
      print('🔌 محاولة الاتصال بـ $ipAddress:$port...');

      // فتح WebSocket
      final wsUrl = Uri.parse('ws://$ipAddress:$port/ws');
      _channel = WebSocketChannel.connect(wsUrl);

      // انتظار الاتصال
      await _channel!.ready.timeout(const Duration(seconds: 10));

      print('✅ متصل بالجهاز');

      // المصادقة
      final authenticated = await _authenticate(password);
      if (!authenticated) {
        print('❌ فشلت المصادقة');
        await disconnect();
        return false;
      }

      _isConnected = true;

      // الاستماع للرسائل
      _listenToMessages();

      print('✅ تم المصادقة بنجاح');
      return true;
    } catch (e) {
      print('❌ خطأ في الاتصال: $e');
      _isConnected = false;
      return false;
    }
  }

  /// المصادقة مع الجهاز
  Future<bool> _authenticate(String password) async {
    try {
      // إرسال كلمة المرور
      _channel?.sink.add(jsonEncode({
        'action': 'authenticate',
        'password': password,
        'timestamp': DateTime.now().toIso8601String(),
      }));

      // انتظار الرد
      final response = await _channel!.stream.first.timeout(
        const Duration(seconds: 5),
      );

      final data = jsonDecode(response as String) as Map<String, dynamic>;
      return data['success'] == true;
    } catch (e) {
      print('❌ خطأ في المصادقة: $e');
      return false;
    }
  }

  /// الاستماع للرسائل الواردة
  void _listenToMessages() {
    _channel?.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          _messageController.add(data);
          print('📨 رسالة واردة: $data');
        } catch (e) {
          print('❌ خطأ في معالجة الرسالة: $e');
        }
      },
      onError: (error) {
        print('❌ خطأ في الاتصال: $error');
        _isConnected = false;
      },
      onDone: () {
        print('⚠️ تم قطع الاتصال');
        _isConnected = false;
      },
    );
  }

  /// قطع الاتصال
  Future<void> disconnect() async {
    try {
      await _channel?.sink.close(status.goingAway);
      _isConnected = false;
      _connectedDeviceId = null;
      print('✅ تم قطع الاتصال');
    } catch (e) {
      print('❌ خطأ في قطع الاتصال: $e');
    }
  }

  // ============================================================================
  // أوامر الروليهات
  // ============================================================================

  /// تشغيل/إيقاف روليه
  Future<bool> toggleRelay({
    required int relayId,
    required bool newState,
  }) async {
    try {
      if (!_isConnected) {
        print('❌ الجهاز غير متصل');
        return false;
      }

      _channel?.sink.add(jsonEncode({
        'action': 'toggle_relay',
        'relay_id': relayId,
        'state': newState,
        'timestamp': DateTime.now().toIso8601String(),
      }));

      print('✅ تم إرسال أمر التبديل للروليه $relayId');
      return true;
    } catch (e) {
      print('❌ خطأ في التبديل: $e');
      return false;
    }
  }

  /// تشغيل روليه بمؤقت (ثوان)
  Future<bool> toggleRelayWithTimer({
    required int relayId,
    required int durationSeconds,
  }) async {
    try {
      if (!_isConnected) return false;

      _channel?.sink.add(jsonEncode({
        'action': 'toggle_relay_timer',
        'relay_id': relayId,
        'duration': durationSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      }));

      print('✅ تم إرسال أمر المؤقت للروليه $relayId ($durationSeconds ثانية)');
      return true;
    } catch (e) {
      print('❌ خطأ في المؤقت: $e');
      return false;
    }
  }

  /// الحصول على حالة جميع الروليهات
  Future<List<Relay>?> getRelaysStatus() async {
    try {
      if (!_isConnected) return null;

      _channel?.sink.add(jsonEncode({
        'action': 'get_relays',
        'timestamp': DateTime.now().toIso8601String(),
      }));

      // انتظار الرد
      final response = await _channel!.stream.first.timeout(
        const Duration(seconds: 5),
      );

      final data = jsonDecode(response as String) as Map<String, dynamic>;
      
      if (data['action'] == 'relays_status') {
        final relaysList = (data['relays'] as List<dynamic>?)
                ?.map((r) => Relay.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [];
        return relaysList;
      }

      return null;
    } catch (e) {
      print('❌ خطأ في جلب الحالة: $e');
      return null;
    }
  }

  // ============================================================================
  // البث المباشر
  // ============================================================================

  /// Stream للرسائل الواردة
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Stream لتحديثات الروليهات
  Stream<Relay> get relayUpdates => _messageController.stream
      .where((msg) => msg['action'] == 'relay_changed')
      .map((msg) => Relay.fromJson(msg['relay'] as Map<String, dynamic>));

  /// Stream لتحديثات الحساسات
  Stream<Map<String, dynamic>> get sensorUpdates => _messageController.stream
      .where((msg) => msg['action'] == 'sensor_data');

  // ============================================================================
  // الإيقاف
  // ============================================================================

  /// تنظيف الموارد
  Future<void> dispose() async {
    await disconnect();
    await _messageController.close();
    print('✅ تم تنظيف الموارد');
  }
}