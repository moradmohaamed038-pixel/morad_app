library;

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'esp_device_model.dart';
import 'relay_model.dart';
import 'command_model.dart';

/// خدمة تزامن البيانات مع Firebase
class CloudSyncService {
  // مراجع Firebase
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream للأجهزة المتزامنة
  final _devicesController = StreamController<List<EspDevice>>.broadcast();
  
  // Stream لتحديثات الأوامر
  final _commandsController = StreamController<DeviceCommand>.broadcast();

  // ============================================================================
  // التزامن الأساسي
  // ============================================================================

  /// تزامن الأجهزة من Firebase
  Stream<List<EspDevice>> syncDevices() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _db.ref('devices').onValue.map((event) {
      try {
        if (!event.snapshot.exists) return [];

        final devices = <EspDevice>[];
        for (var child in event.snapshot.children) {
          final device = EspDevice.fromJson(
            Map<String, dynamic>.from(child.value as Map)
          );

          // فلترة: فقط الأجهزة المملوكة أو المشاركة
          if (device.ownerId == userId || 
              device.sharedWith.containsKey(userId)) {
            devices.add(device);
          }
        }

        _devicesController.add(devices);
        return devices;
      } catch (e) {
        print('❌ خطأ في التزامن: $e');
        return [];
      }
    });
  }

  /// حفظ أمر في Firebase
  Future<bool> recordCommand({
    required String deviceId,
    required int relayId,
    required bool newState,
    required String source, // "local" أو "cloud"
  }) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      final commandId = _db.ref('commands').push().key;
      
      if (commandId == null) return false;

      final command = DeviceCommand(
        id: commandId,
        deviceId: deviceId,
        relayId: relayId,
        targetState: newState,
        source: source,
        userId: userId,
        timestamp: DateTime.now(),
        status: 'executed',
      );

      await _db.ref('commands/$deviceId/$commandId').set(command.toJson());
      _commandsController.add(command);

      print('✅ تم حفظ الأمر في السحابة');
      return true;
    } catch (e) {
      print('❌ خطأ في حفظ الأمر: $e');
      return false;
    }
  }

  /// تحديث حالة جهاز
  Future<bool> updateDeviceStatus(String deviceId, String status) async {
    try {
      await _db.ref('devices/$deviceId/status').set(status);
      await _db.ref('devices/$deviceId/updatedAt').set(DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      print('❌ خطأ في التحديث: $e');
      return false;
    }
  }

  // ============================================================================
  // البث المباشر
  // ============================================================================

  Stream<List<EspDevice>> get devices => _devicesController.stream;
  Stream<DeviceCommand> get commands => _commandsController.stream;

  // ============================================================================
  // الإيقاف
  // ============================================================================

  Future<void> dispose() async {
    await _devicesController.close();
    await _commandsController.close();
  }
}