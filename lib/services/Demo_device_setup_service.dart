library;

import 'esp_device_model.dart';
import 'relay_model.dart';
import 'sensor_model.dart';

/// خدمة إنشاء لوحات افتراضية للتجربة والعرض
class DemoDeviceSetupService {
  /// إنشاء لوحة افتراضية كاملة
  static EspDevice createFullDemoDevice() {
    return EspDevice(
      id: 'demo_device_001',
      name: 'لوحة تجريبية',
      location: 'المختبر',
      localPin: '1234',
      ownerId: 'demo_user',
      status: 'demo',
      isDemo: true,
      relays: _createDemoRelays(),
      sensors: _createDemoSensors(),
      deviceType: 'Demo ESP32',
      firmwareVersion: '2.0.0-demo',
      maxRelays: 8,
      maxSensors: 8,
    );
  }

  /// إنشاء لوحة افتراضية بسيطة (للمبتدئين)
  static EspDevice createSimpleDemoDevice() {
    return EspDevice(
      id: 'demo_device_simple',
      name: 'لوحة بسيطة',
      location: 'المنزل',
      localPin: '1111',
      ownerId: 'demo_user',
      status: 'demo',
      isDemo: true,
      relays: [
        Relay(
          id: 1,
          name: 'الإضاءة',
          pin: 5,
          state: false,
          icon: '💡',
          type: 'light',
        ),
        Relay(
          id: 2,
          name: 'المروحة',
          pin: 6,
          state: false,
          icon: '🌀',
          type: 'fan',
        ),
      ],
      sensors: [
        Sensor(
          id: 1,
          name: 'درجة الحرارة',
          pin: 0,
          type: 'temperature',
          value: 22.5,
          unit: '°C',
          minValue: 0,
          maxValue: 50,
          icon: '🌡️',
        ),
      ],
    );
  }

  /// إنشاء لوحة افتراضية متقدمة (للخبراء)
  static EspDevice createAdvancedDemoDevice() {
    return EspDevice(
      id: 'demo_device_advanced',
      name: 'لوحة متقدمة',
      location: 'المصنع',
      localPin: '9999',
      ownerId: 'demo_user',
      status: 'demo',
      isDemo: true,
      relays: _createAdvancedRelays(),
      sensors: _createAdvancedSensors(),
      deviceType: 'Demo Industrial ESP32',
      firmwareVersion: '3.0.0-demo-pro',
      maxRelays: 16,
      maxSensors: 16,
    );
  }

  // ============================================================================
  // الروليهات التجريبية
  // ============================================================================

  static List<Relay> _createDemoRelays() {
    return [
      Relay(
        id: 1,
        name: 'إضاءة غرفة المعيشة',
        pin: 5,
        state: false,
        icon: '💡',
        description: 'إضاءة LED بيضاء',
        color: '#FFD700',
        type: 'light',
      ),
      Relay(
        id: 2,
        name: 'مروحة التبريد',
        pin: 6,
        state: false,
        icon: '🌀',
        description: 'مروحة سقفية',
        color: '#4169E1',
        type: 'fan',
      ),
      Relay(
        id: 3,
        name: 'المكيف',
        pin: 7,
        state: false,
        icon: '❄️',
        description: 'وحدة تكييف الهواء',
        color: '#00CED1',
        type: 'motor',
        isCritical: true,
      ),
      Relay(
        id: 4,
        name: 'المضخة',
        pin: 8,
        state: false,
        icon: '💧',
        description: 'مضخة المياه',
        color: '#1E90FF',
        type: 'pump',
      ),
      Relay(
        id: 5,
        name: 'السخان',
        pin: 9,
        state: true,
        icon: '🔥',
        description: 'سخان الماء الكهربائي',
        color: '#FF4500',
        type: 'motor',
        isCritical: true,
      ),
      Relay(
        id: 6,
        name: 'نظام الإنذار',
        pin: 10,
        state: false,
        icon: '🚨',
        description: 'جرس الإنذار',
        color: '#FF0000',
        type: 'switch',
        isCritical: true,
      ),
      Relay(
        id: 7,
        name: 'أضواء خارجية',
        pin: 11,
        state: false,
        icon: '🌃',
        description: 'أضواء الحديقة',
        color: '#FFD700',
        type: 'light',
      ),
      Relay(
        id: 8,
        name: 'النافورة',
        pin: 12,
        state: false,
        icon: '⛲',
        description: 'نافورة الحديقة',
        color: '#00CED1',
        type: 'pump',
      ),
    ];
  }

  static List<Relay> _createAdvancedRelays() {
    return [
      ..._createDemoRelays(),
      Relay(
        id: 9,
        name: 'خط الإنتاج 1',
        pin: 13,
        state: false,
        icon: '🏭',
        description: 'خط الإنتاج الرئيسي',
        color: '#FF8C00',
        type: 'motor',
        isCritical: true,
      ),
      Relay(
        id: 10,
        name: 'خط الإنتاج 2',
        pin: 14,
        state: false,
        icon: '🏭',
        description: 'خط الإنتاج الثانوي',
        color: '#FF8C00',
        type: 'motor',
        isCritical: true,
      ),
    ];
  }

  // ============================================================================
  // الحساسات التجريبية
  // ============================================================================

  static List<Sensor> _createDemoSensors() {
    return [
      Sensor(
        id: 1,
        name: 'درجة الحرارة الداخلية',
        pin: 0,
        type: 'temperature',
        value: 22.5,
        unit: '°C',
        minValue: 0,
        maxValue: 50,
        icon: '🌡️',
        description: 'حساس درجة الحرارة DHT22',
        color: '#FF6347',
        warningThreshold: 35,
      ),
      Sensor(
        id: 2,
        name: 'الرطوبة النسبية',
        pin: 1,
        type: 'humidity',
        value: 65.3,
        unit: '%',
        minValue: 0,
        maxValue: 100,
        icon: '💧',
        description: 'حساس الرطوبة DHT22',
        color: '#4169E1',
        warningThreshold: 80,
      ),
      Sensor(
        id: 3,
        name: 'الضغط الجوي',
        pin: 2,
        type: 'pressure',
        value: 1013.25,
        unit: 'hPa',
        minValue: 900,
        maxValue: 1100,
        icon: '📊',
        description: 'حساس الضغط BMP280',
        color: '#228B22',
      ),
      Sensor(
        id: 4,
        name: 'مستوى الإضاءة',
        pin: 3,
        type: 'light',
        value: 75.5,
        unit: '%',
        minValue: 0,
        maxValue: 100,
        icon: '☀️',
        description: 'حساس الضوء LDR',
        color: '#FFD700',
      ),
    ];
  }

  static List<Sensor> _createAdvancedSensors() {
    return [
      ..._createDemoSensors(),
      Sensor(
        id: 5,
        name: 'كشف الحركة',
        pin: 4,
        type: 'motion',
        value: 0,
        unit: 'bool',
        minValue: 0,
        maxValue: 1,
        icon: '👁️',
        description: 'حساس PIR للحركة',
        color: '#FF0000',
      ),
      Sensor(
        id: 6,
        name: 'رطوبة التربة',
        pin: 5,
        type: 'soil_moisture',
        value: 45.2,
        unit: '%',
        minValue: 0,
        maxValue: 100,
        icon: '🌱',
        description: 'حساس رطوبة التربة',
        color: '#8B4513',
        warningThreshold: 30,
      ),
      Sensor(
        id: 7,
        name: 'مستشعر الغاز',
        pin: 6,
        type: 'gas',
        value: 150,
        unit: 'ppm',
        minValue: 0,
        maxValue: 500,
        icon: '💨',
        description: 'حساس الغاز MQ-7',
        color: '#DC143C',
        warningThreshold: 400,
      ),
      Sensor(
        id: 8,
        name: 'مسافة الاقتراب',
        pin: 7,
        type: 'distance',
        value: 25.3,
        unit: 'cm',
        minValue: 2,
        maxValue: 400,
        icon: '📏',
        description: 'حساس المسافة بالموجات فوق الصوتية',
        color: '#00BFFF',
      ),
    ];
  }

  /// تحديث قيمة حساس (محاكاة التغيير)
  static EspDevice updateDemoSensorValue(
    EspDevice device,
    int sensorId,
    double newValue,
  ) {
    final updatedSensors = device.sensors.map((sensor) {
      if (sensor.id == sensorId) {
        return sensor.copyWith(
          value: newValue,
          lastUpdate: DateTime.now(),
        );
      }
      return sensor;
    }).toList();

    return device.copyWith(sensors: updatedSensors);
  }

  /// تبديل حالة روليه (محاكاة التغيير)
  static EspDevice toggleDemoRelay(EspDevice device, int relayId) {
    final updatedRelays = device.relays.map((relay) {
      if (relay.id == relayId) {
        return relay.toggle();
      }
      return relay;
    }).toList();

    return device.copyWith(relays: updatedRelays);
  }
}