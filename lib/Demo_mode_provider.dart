library;

import 'package:flutter/material.dart';
import 'dart:async';
import '../models/esp_device_model.dart';
import '../models/relay_model.dart';
import '../models/sensor_model.dart';
import '../services/demo_device_setup_service.dart';

/// إدارة الوضع الافتراضي (Demo Mode)
/// يحاكي الأجهزة الحقيقية للتجربة والعرض
class DemoModeProvider extends ChangeNotifier {
  // ============================================================================
  // المتغيرات الخاصة
  // ============================================================================

  /// الجهاز الافتراضي الحالي
  late EspDevice _demoDevice;

  /// هل يتم محاكاة التحديثات؟
  bool _isSimulating = false;

  /// Timer للمحاكاة
  Timer? _simulationTimer;

  /// قيم الحساسات الحالية (للمحاكاة)
  Map<int, double> _sensorValues = {};

  // ============================================================================
  // Getters
  // ============================================================================

  EspDevice get demoDevice => _demoDevice;
  bool get isSimulating => _isSimulating;
  List<Relay> get relays => _demoDevice.relays;
  List<Sensor> get sensors => _demoDevice.sensors;

  // ============================================================================
  // التهيئة
  // ============================================================================

  /// بناء Provider
  DemoModeProvider() {
    _initializeDemoDevice();
  }

  /// تهيئة الجهاز الافتراضي
  void _initializeDemoDevice() {
    _demoDevice = DemoDeviceSetupService.createFullDemoDevice();
    
    // تهيئة قيم الحساسات
    for (var sensor in _demoDevice.sensors) {
      _sensorValues[sensor.id] = sensor.value;
    }

    print('✅ تم تهيئة Demo Mode');
  }

  // ============================================================================
  // التحكم بالروليهات
  // ============================================================================

  /// تبديل حالة روليه
  void toggleRelay(int relayId) {
    _demoDevice = DemoDeviceSetupService.toggleDemoRelay(_demoDevice, relayId);
    print('⚡ تبديل الروليه $relayId');
    notifyListeners();
  }

  /// تشغيل روليه بمؤقت
  void toggleRelayWithTimer(int relayId, int durationSeconds) {
    // تبديل الروليه
    toggleRelay(relayId);

    // إنشاء مؤقت
    Future.delayed(Duration(seconds: durationSeconds), () {
      if (_demoDevice.relays.any((r) => r.id == relayId)) {
        toggleRelay(relayId);
      }
    });

    print('⏱️ تشغيل الروليه $relayId لمدة $durationSeconds ثانية');
  }

  // ============================================================================
  // المحاكاة
  // ============================================================================

  /// بدء محاكاة التحديثات
  void startSimulation() {
    if (_isSimulating) return;

    _isSimulating = true;
    print('🎮 بدء محاكاة التحديثات...');

    // تحديث الحساسات كل ثانية
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _simulateSensorUpdates();
    });

    notifyListeners();
  }

  /// إيقاف المحاكاة
  void stopSimulation() {
    _simulationTimer?.cancel();
    _isSimulating = false;
    print('🛑 إيقاف المحاكاة');
    notifyListeners();
  }

  /// محاكاة تحديثات الحساسات
  void _simulateSensorUpdates() {
    final updatedSensors = <Sensor>[];

    for (var sensor in _demoDevice.sensors) {
      double newValue = _sensorValues[sensor.id] ?? sensor.value;

      // محاكاة التغييرات حسب نوع الحساس
      switch (sensor.type) {
        case 'temperature':
          // تغيير عشوائي صغير
          newValue += (DateTime.now().millisecond % 2 == 0 ? 0.1 : -0.1);
          newValue = newValue.clamp(sensor.minValue, sensor.maxValue);
          break;

        case 'humidity':
          // تغيير عشوائي أكبر
          newValue += (DateTime.now().millisecond % 3 == 0 ? 2 : -1);
          newValue = newValue.clamp(sensor.minValue, sensor.maxValue);
          break;

        case 'light':
          // تقلب حسب الروليهات
          if (_demoDevice.relays.any((r) => r.name.contains('إضاءة') && r.state)) {
            newValue = 100;
          } else {
            newValue = 20;
          }
          break;

        default:
          break;
      }

      _sensorValues[sensor.id] = newValue;

      // تحديث الحساس
      updatedSensors.add(sensor.copyWith(
        value: newValue,
        lastUpdate: DateTime.now(),
      ));
    }

    // تحديث الجهاز
    _demoDevice = _demoDevice.copyWith(sensors: updatedSensors);
    notifyListeners();
  }

  /// تحديث قيمة حساس يدوياً
  void updateSensorValue(int sensorId, double newValue) {
    _demoDevice = DemoDeviceSetupService.updateDemoSensorValue(
      _demoDevice,
      sensorId,
      newValue,
    );

    _sensorValues[sensorId] = newValue;
    print('📊 تحديث الحساس $sensorId = $newValue');
    notifyListeners();
  }

  // ============================================================================
  // الإحصائيات
  // ============================================================================

  /// عدد الروليهات النشطة
  int get activeRelaysCount => _demoDevice.activeRelaysCount;

  /// عدد الحساسات
  int get sensorsCount => _demoDevice.sensorsCount;

  /// هل يوجد روليهات؟
  bool get hasRelays => _demoDevice.hasRelays;

  /// هل يوجد حساسات؟
  bool get hasSensors => _demoDevice.hasSensors;

  // ============================================================================
  // التنظيف
  // ============================================================================

  @override
  void dispose() {
    stopSimulation();
    super.dispose();
  }
}