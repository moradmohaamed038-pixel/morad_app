library;

import 'package:flutter/material.dart';
import '../models/esp_device_model.dart';
import '../models/relay_model.dart';
import '../models/sensor_model.dart';
import '../services/device_discovery_service.dart';
import '../services/local_connection_service.dart';
import '../services/demo_device_setup_service.dart';
import '../services/cloud_sync_service.dart';

/// إدارة الأجهزة (Devices)
/// يتحكم في:
/// - قائمة الأجهزة
/// - الجهاز النشط الحالي
/// - البحث عن أجهزة جديدة
/// - تحديث بيانات الأجهزة
class DeviceProvider extends ChangeNotifier {
  // ============================================================================
  // المتغيرات الخاصة
  // ============================================================================

  /// قائمة جميع الأجهزة (المحلية والسحابية والافتراضية)
  List<EspDevice> _devices = [];

  /// الجهاز النشط الحالي
  EspDevice? _activeDevice;

  /// خدمة البحث عن الأجهزة
  late DeviceDiscoveryService _discoveryService;

  /// خدمة الاتصال المحلي
  late LocalConnectionService _localConnection;

  /// خدمة تزامن السحابة
  late CloudSyncService _cloudSync;

  /// حالة البحث
  bool _isSearching = false;

  /// رسالة الخطأ
  String? _errorMessage;

  /// حالة الاتصال بالجهاز النشط
  bool _isConnected = false;

  /// الأجهزة المكتشفة (أثناء البحث)
  List<EspDevice> _discoveredDevices = [];

  // ============================================================================
  // Getters
  // ============================================================================

  /// قائمة الأجهزة
  List<EspDevice> get devices => List.unmodifiable(_devices);

  /// الجهاز النشط
  EspDevice? get activeDevice => _activeDevice;

  /// هل يتم البحث؟
  bool get isSearching => _isSearching;

  /// رسالة الخطأ
  String? get errorMessage => _errorMessage;

  /// هل متصل بالجهاز النشط؟
  bool get isConnected => _isConnected;

  /// الأجهزة المكتشفة
  List<EspDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  /// عدد الأجهزة
  int get deviceCount => _devices.length;

  /// هل يوجد أجهزة؟
  bool get hasDevices => _devices.isNotEmpty;

  /// هل الجهاز النشط متصل محلياً؟
  bool get isLocallyConnected => _isConnected && _activeDevice?.isConnected == true;

  // ============================================================================
  // التهيئة
  // ============================================================================

  /// بناء Provider
  DeviceProvider() {
    _initializeServices();
  }

  /// تهيئة الخدمات
  void _initializeServices() {
    _discoveryService = DeviceDiscoveryService();
    _localConnection = LocalConnectionService();
    _cloudSync = CloudSyncService();
    print('✅ تم تهيئة Device Provider');
  }

  // ============================================================================
  // البحث والاكتشاف
  // ============================================================================

  /// بدء البحث عن أجهزة ESP32
  Future<void> searchForDevices() async {
    try {
      _isSearching = true;
      _errorMessage = null;
      _discoveredDevices = [];
      notifyListeners();

      print('🔍 بدء البحث عن الأجهزة...');

      // تهيئة خدمة البحث
      await _discoveryService.initialize();

      // البحث عن الأجهزة
      final discovered = await _discoveryService.discoverDevices(
        timeout: const Duration(seconds: 15),
      );

      _discoveredDevices = discovered;

      print('✅ وجدت ${discovered.length} أجهزة');
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في البحث: $e');
      _errorMessage = 'خطأ في البحث: $e';
      _isSearching = false;
      notifyListeners();
    }
  }

  /// إضافة جهاز تم اكتشافه
  Future<void> addDiscoveredDevice(EspDevice device) async {
    try {
      // تجنب التكرار
      if (_devices.any((d) => d.id == device.id)) {
        _errorMessage = 'هذا الجهاز موجود بالفعل';
        notifyListeners();
        return;
      }

      _devices.add(device);
      _errorMessage = null;
      print('✅ تم إضافة الجهاز: ${device.name}');
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في إضافة الجهاز: $e');
      _errorMessage = 'خطأ: $e';
      notifyListeners();
    }
  }

  /// إضافة جهاز افتراضي (Demo)
  void addDemoDevice({bool advanced = false}) {
    try {
      final demoDevice = advanced
          ? DemoDeviceSetupService.createAdvancedDemoDevice()
          : DemoDeviceSetupService.createSimpleDemoDevice();

      // تجنب التكرار
      if (_devices.any((d) => d.id == demoDevice.id)) {
        _errorMessage = 'الجهاز الافتراضي موجود بالفعل';
        notifyListeners();
        return;
      }

      _devices.add(demoDevice);
      setActiveDevice(demoDevice);

      print('✅ تم إضافة جهاز افتراضي: ${demoDevice.name}');
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في إضافة الجهاز الافتراضي: $e');
      _errorMessage = 'خطأ: $e';
      notifyListeners();
    }
  }

  // ============================================================================
  // إدارة الجهاز النشط
  // ============================================================================

  /// تعيين الجهاز النشط
  Future<void> setActiveDevice(EspDevice device) async {
    try {
      print('🎯 تعيين الجهاز النشط: ${device.name}');

      _activeDevice = device;
      _isConnected = false;
      _errorMessage = null;

      notifyListeners();

      // محاولة الاتصال إذا كان الجهاز متاحاً محلياً
      if (device.ipAddress != null && !device.isDemo) {
        await connectToLocalDevice(device);
      }
    } catch (e) {
      print('❌ خطأ في تعيين الجهاز: $e');
      _errorMessage = 'خطأ: $e';
      notifyListeners();
    }
  }

  /// الاتصال بجهاز محلي
  Future<bool> connectToLocalDevice(EspDevice device) async {
    try {
      if (device.ipAddress == null) {
        throw Exception('لا يوجد عنوان IP');
      }

      print('🔌 محاولة الاتصال بـ ${device.name}...');

      final connected = await _localConnection.connect(
        ipAddress: device.ipAddress!,
        port: device.port ?? 8080,
        password: device.localPin,
      );

      if (connected) {
        _isConnected = true;
        _errorMessage = null;
        print('✅ متصل بالجهاز محلياً');
      } else {
        _isConnected = false;
        _errorMessage = 'فشل الاتصال المحلي';
        print('❌ فشل الاتصال');
      }

      notifyListeners();
      return connected;
    } catch (e) {
      print('❌ خطأ في الاتصال: $e');
      _errorMessage = 'خطأ: $e';
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  /// قطع الاتصال
  Future<void> disconnect() async {
    try {
      await _localConnection.disconnect();
      _isConnected = false;
      print('✅ تم قطع الاتصال');
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في قطع الاتصال: $e');
    }
  }

  // ============================================================================
  // التحكم بالروليهات
  // ============================================================================

  /// تبديل حالة روليه
  Future<bool> toggleRelay(int relayId, bool newState) async {
    try {
      if (_activeDevice == null) {
        throw Exception('لا يوجد جهاز نشط');
      }

      print('⚡ تبديل الروليه $relayId إلى $newState');

      bool success = false;

      // إذا كان الجهاز متصلاً محلياً
      if (_isConnected && _activeDevice!.ipAddress != null) {
        success = await _localConnection.toggleRelay(
          relayId: relayId,
          newState: newState,
        );
      }

      // تحديث الحالة المحلية
      if (success) {
        _updateRelayState(_activeDevice!.id, relayId, newState);

        // حفظ في السحابة بالخلفية
        await _cloudSync.recordCommand(
          deviceId: _activeDevice!.id,
          relayId: relayId,
          newState: newState,
          source: 'local',
        );

        _errorMessage = null;
      } else {
        _errorMessage = 'فشل التبديل';
      }

      notifyListeners();
      return success;
    } catch (e) {
      print('❌ خطأ في التبديل: $e');
      _errorMessage = 'خطأ: $e';
      notifyListeners();
      return false;
    }
  }

  /// تشغيل روليه بمؤقت (دقائق)
  Future<bool> toggleRelayWithTimer({
    required int relayId,
    required int durationMinutes,
  }) async {
    try {
      if (_activeDevice == null) {
        throw Exception('لا يوجد جهاز نشط');
      }

      print('⏱️ تشغيل الروليه $relayId لمدة $durationMinutes دقيقة');

      final durationSeconds = durationMinutes * 60;

      // إرسال الأمر للجهاز المحلي
      bool success = false;
      if (_isConnected) {
        success = await _localConnection.toggleRelayWithTimer(
          relayId: relayId,
          durationSeconds: durationSeconds,
        );
      }

      if (success) {
        // تحديث الحالة المحلية
        _updateRelayState(_activeDevice!.id, relayId, true);
        
        _errorMessage = null;
      } else {
        _errorMessage = 'فشل تشغيل المؤقت';
      }

      notifyListeners();
      return success;
    } catch (e) {
      print('❌ خطأ في المؤقت: $e');
      _errorMessage = 'خطأ: $e';
      notifyListeners();
      return false;
    }
  }

  /// تحديث حالة روليه محلياً
  void _updateRelayState(String deviceId, int relayId, bool newState) {
    final deviceIndex = _devices.indexWhere((d) => d.id == deviceId);
    if (deviceIndex == -1) return;

    final device = _devices[deviceIndex];
    final relayIndex = device.relays.indexWhere((r) => r.id == relayId);
    if (relayIndex == -1) return;

    // تحديث الروليه
    final updatedRelays = [...device.relays];
    updatedRelays[relayIndex] = updatedRelays[relayIndex].copyWith(
      state: newState,
      lastManualChange: DateTime.now(),
    );

    // تحديث الجهاز
    final updatedDevice = device.copyWith(relays: updatedRelays);
    _devices[deviceIndex] = updatedDevice;

    // تحديث الجهاز النشط إن كان
    if (_activeDevice?.id == deviceId) {
      _activeDevice = updatedDevice;
    }
  }

  // ============================================================================
  // جلب البيانات الحية
  // ============================================================================

  /// جلب حالة جميع الروليهات من الجهاز
  Future<bool> refreshRelaysStatus() async {
    try {
      if (!_isConnected || _activeDevice == null) {
        return false;
      }

      print('🔄 تحديث حالة الروليهات...');

      final relays = await _localConnection.getRelaysStatus();
      if (relays != null) {
        final updatedDevice = _activeDevice!.copyWith(relays: relays);
        
        // تحديث في القائمة
        final index = _devices.indexWhere((d) => d.id == _activeDevice!.id);
        if (index != -1) {
          _devices[index] = updatedDevice;
        }

        _activeDevice = updatedDevice;
        _errorMessage = null;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      print('❌ خطأ في التحديث: $e');
      _errorMessage = 'خطأ: $e';
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // الأجهزة الافتراضية (محاكاة)
  // ============================================================================

  /// تحديث قيمة حساس (للأجهزة الافتراضية)
  void updateDemoSensorValue(int sensorId, double newValue) {
    if (_activeDevice == null || !_activeDevice!.isDemoDevice) return;

    final updated = DemoDeviceSetupService.updateDemoSensorValue(
      _activeDevice!,
      sensorId,
      newValue,
    );

    _activeDevice = updated;
    
    // تحديث في القائمة
    final index = _devices.indexWhere((d) => d.id == _activeDevice!.id);
    if (index != -1) {
      _devices[index] = updated;
    }

    notifyListeners();
  }

  /// تبديل روليه افتراضي
  void toggleDemoRelay(int relayId) {
    if (_activeDevice == null || !_activeDevice!.isDemoDevice) return;

    final updated = DemoDeviceSetupService.toggleDemoRelay(
      _activeDevice!,
      relayId,
    );

    _activeDevice = updated;

    // تحديث في القائمة
    final index = _devices.indexWhere((d) => d.id == _activeDevice!.id);
    if (index != -1) {
      _devices[index] = updated;
    }

    notifyListeners();
  }

  // ============================================================================
  // إدارة الأجهزة
  // ============================================================================

  /// حذف جهاز
  Future<bool> deleteDevice(String deviceId) async {
    try {
      print('🗑️ حذف الجهاز: $deviceId');

      // إذا كان الجهاز النشط، قطع الاتصال
      if (_activeDevice?.id == deviceId) {
        await disconnect();
        _activeDevice = null;
      }

      _devices.removeWhere((d) => d.id == deviceId);

      // اختر جهاز جديد إن أمكن
      if (_devices.isNotEmpty) {
        await setActiveDevice(_devices.first);
      }

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ خطأ في الحذف: $e');
      _errorMessage = 'خطأ: $e';
      notifyListeners();
      return false;
    }
  }

  /// تحديث بيانات جهاز
  void updateDevice(EspDevice updatedDevice) {
    final index = _devices.indexWhere((d) => d.id == updatedDevice.id);
    if (index != -1) {
      _devices[index] = updatedDevice;

      if (_activeDevice?.id == updatedDevice.id) {
        _activeDevice = updatedDevice;
      }

      notifyListeners();
    }
  }

  /// إعادة تسمية جهاز
  void renameDevice(String deviceId, String newName) {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(name: newName);

      if (_activeDevice?.id == deviceId) {
        _activeDevice = _devices[index];
      }

      notifyListeners();
    }
  }

  /// البحث عن جهاز برقمه
  EspDevice? getDeviceById(String deviceId) {
    try {
      return _devices.firstWhere((d) => d.id == deviceId);
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // الإحصائيات
  // ============================================================================

  /// عدد الأجهزة المتصلة
  int get connectedDeviceCount => _devices.where((d) => d.isConnected).length;

  /// عدد الأجهزة المعطلة
  int get offlineDeviceCount => _devices.where((d) => !d.isConnected).length;

  /// عدد الروليهات النشطة في الجهاز الحالي
  int get activeRelaysInCurrentDevice => _activeDevice?.activeRelaysCount ?? 0;

  /// عدد الحساسات في الجهاز الحالي
  int get sensorsInCurrentDevice => _activeDevice?.sensorsCount ?? 0;

  // ============================================================================
  // التنظيف
  // ============================================================================

  @override
  Future<void> dispose() async {
    await _localConnection.dispose();
    await _discoveryService.dispose();
    await _cloudSync.dispose();
    super.dispose();
  }
}