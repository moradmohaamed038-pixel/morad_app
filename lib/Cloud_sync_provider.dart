library;

import 'package:flutter/material.dart';
import 'dart:async';
import '../models/esp_device_model.dart';
import '../models/command_model.dart';
import '../services/cloud_sync_service.dart';

/// إدارة التزامن مع Firebase
/// يتحكم في:
/// - جلب الأجهزة من السحابة
/// - حفظ الأوامر
/// - استقبال التحديثات من مستخدمين آخرين
class CloudSyncProvider extends ChangeNotifier {
  // ============================================================================
  // المتغيرات الخاصة
  // ============================================================================

  /// خدمة التزامن
  late CloudSyncService _syncService;

  /// قائمة الأجهزة المتزامنة
  List<EspDevice> _syncedDevices = [];

  /// الأوامر الأخيرة
  List<DeviceCommand> _recentCommands = [];

  /// حالة التزامن
  bool _isSyncing = false;

  /// رسالة الخطأ
  String? _errorMessage;

  /// آخر وقت تزامن
  DateTime? _lastSyncTime;

  /// عدد الأوامر المعلقة
  int _pendingCommands = 0;

  /// Subscriptions
  StreamSubscription? _devicesSubscription;
  StreamSubscription? _commandsSubscription;

  // ============================================================================
  // Getters
  // ============================================================================

  List<EspDevice> get syncedDevices => List.unmodifiable(_syncedDevices);
  List<DeviceCommand> get recentCommands => List.unmodifiable(_recentCommands);
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingCommands => _pendingCommands;

  // ============================================================================
  // التهيئة
  // ============================================================================

  CloudSyncProvider() {
    _syncService = CloudSyncService();
    print('✅ تم تهيئة Cloud Sync Provider');
  }

  // ============================================================================
  // التزامن الأساسي
  // ============================================================================

  /// بدء التزامن
  Future<void> startSync() async {
    try {
      print('☁️ بدء التزامن مع Firebase...');

      _isSyncing = true;
      _errorMessage = null;
      notifyListeners();

      // الاستماع لتحديثات الأجهزة
      _devicesSubscription = _syncService.devices.listen(
        (devices) {
          _syncedDevices = devices;
          _lastSyncTime = DateTime.now();
          _errorMessage = null;
          print('✅ تم تحديث الأجهزة من السحابة: ${devices.length} جهاز');
          notifyListeners();
        },
        onError: (error) {
          print('❌ خطأ في تزامن الأجهزة: $error');
          _errorMessage = 'خطأ: $error';
          notifyListeners();
        },
      );

      // الاستماع للأوامر الجديدة
      _commandsSubscription = _syncService.commands.listen(
        (command) {
          _recentCommands.insert(0, command);

          // احفظ آخر 50 أمر فقط
          if (_recentCommands.length > 50) {
            _recentCommands = _recentCommands.sublist(0, 50);
          }

          print('📝 أمر جديد: ${command.id}');
          notifyListeners();
        },
        onError: (error) {
          print('❌ خطأ في تزامن الأوامر: $error');
        },
      );

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في بدء التزامن: $e');
      _errorMessage = 'خطأ: $e';
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// إيقاف التزامن
  Future<void> stopSync() async {
    await _devicesSubscription?.cancel();
    await _commandsSubscription?.cancel();
    await _syncService.dispose();
    print('🛑 تم إيقاف التزامن');
  }

  // ============================================================================
  // حفظ الأوامر
  // ============================================================================

  /// حفظ أمر في السحابة
  Future<bool> recordCommand({
    required String deviceId,
    required int relayId,
    required bool newState,
    required String source, // "local" أو "cloud"
  }) async {
    try {
      print('📤 حفظ أمر في السحابة...');

      _pendingCommands++;
      notifyListeners();

      final success = await _syncService.recordCommand(
        deviceId: deviceId,
        relayId: relayId,
        newState: newState,
        source: source,
      );

      _pendingCommands--;

      if (success) {
        _errorMessage = null;
        print('✅ تم حفظ الأمر');
      } else {
        _errorMessage = 'فشل حفظ الأمر';
        print('❌ فشل الحفظ');
      }

      notifyListeners();
      return success;
    } catch (e) {
      print('❌ خطأ: $e');
      _errorMessage = 'خطأ: $e';
      _pendingCommands--;
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // إحصائيات التزامن
  // ============================================================================

  /// عدد الأجهزة المتزامنة
  int get syncedDeviceCount => _syncedDevices.length;

  /// عدد الأوامر المسجلة
  int get recordedCommandsCount => _recentCommands.length;

  /// كم منذ آخر تزامن (بالثواني)
  int? get secondsSinceLastSync {
    if (_lastSyncTime == null) return null;
    return DateTime.now().difference(_lastSyncTime!).inSeconds;
  }

  // ============================================================================
  // البحث والتصفية
  // ============================================================================

  /// الأجهزة المتزامنة لجهاز معين
  EspDevice? getSyncedDeviceById(String deviceId) {
    try {
      return _syncedDevices.firstWhere((d) => d.id == deviceId);
    } catch (e) {
      return null;
    }
  }

  /// الأوامر لجهاز معين
  List<DeviceCommand> getCommandsForDevice(String deviceId) {
    return _recentCommands.where((c) => c.deviceId == deviceId).toList();
  }

  /// الأوامر لروليه معينة
  List<DeviceCommand> getCommandsForRelay(String deviceId, int relayId) {
    return _recentCommands
        .where((c) => c.deviceId == deviceId && c.relayId == relayId)
        .toList();
  }

  // ============================================================================
  // التنظيف
  // ============================================================================

  @override
  Future<void> dispose() async {
    await stopSync();
    super.dispose();
  }
}