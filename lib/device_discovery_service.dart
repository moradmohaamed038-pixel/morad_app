library;

import 'package:multicast_dns/multicast_dns.dart';
import 'dart:async';
import 'dart:io';
import 'esp_device_model.dart';
import 'relay_model.dart';
import 'sensor_model.dart';

/// خدمة البحث عن لوحات ESP32 في الشبكة المحلية
class DeviceDiscoveryService {
  // مراجع mDNS
  late MDnsClient _mdnsClient;
  StreamSubscription? _discoverySubscription;

  // قائمة الأجهزة المكتشفة
  final List<EspDevice> _discoveredDevices = [];

  // Stream للبث المباشر
  final _devicesStreamController = StreamController<List<EspDevice>>.broadcast();

  // ============================================================================
  // التهيئة والإغلاق
  // ============================================================================

  /// بدء خدمة البحث
  Future<void> initialize() async {
    try {
      _mdnsClient = MDnsClient();
      await _mdnsClient.start();
      print('✅ خدمة البحث جاهزة');
    } catch (e) {
      print('❌ خطأ في تهيئة البحث: $e');
      rethrow;
    }
  }

  /// إيقاف الخدمة
  Future<void> dispose() async {
    await _discoverySubscription?.cancel();
    _mdnsClient.stop();
    await _devicesStreamController.close();
    print('✅ تم إيقاف خدمة البحث');
  }

  // ============================================================================
  // البحث عن الأجهزة
  // ============================================================================

  /// البحث عن جميع أجهزة ESP32 في الشبكة المحلية
  /// يستخدم mDNS للبحث عن الخدمات
  Future<List<EspDevice>> discoverDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _discoveredDevices.clear();

    try {
      print('🔍 بدء البحث عن الأجهزة...');

      // البحث عن خدمات HTTP
      await _searchForHttpServices(timeout);

      // البحث عن خدمات WebSocket
      await _searchForWebSocketServices(timeout);

      // البحث عن خدمات مخصصة ESP32
      await _searchForEsp32Services(timeout);

      print('✅ وجدت ${_discoveredDevices.length} أجهزة');
      _devicesStreamController.add(_discoveredDevices);

      return _discoveredDevices;
    } catch (e) {
      print('❌ خطأ في البحث: $e');
      return [];
    }
  }

  /// البحث عن خدمات HTTP
  Future<void> _searchForHttpServices(Duration timeout) async {
    try {
      await for (final PtrResourceRecord record in _mdnsClient
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.service('_http._tcp'),
            timeout: timeout,
          )
          .timeout(timeout, onTimeout: () async* {})) {
        
        // استخراج معلومات الجهاز
        final device = await _parseServiceRecord(record.domainName);
        if (device != null) {
          _addDeviceIfNew(device);
        }
      }
    } catch (e) {
      print('⚠️ خطأ في البحث عن خدمات HTTP: $e');
    }
  }

  /// البحث عن خدمات WebSocket
  Future<void> _searchForWebSocketServices(Duration timeout) async {
    try {
      await for (final PtrResourceRecord record in _mdnsClient
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.service('_ws._tcp'),
            timeout: timeout,
          )
          .timeout(timeout, onTimeout: () async* {})) {
        
        final device = await _parseServiceRecord(record.domainName);
        if (device != null) {
          _addDeviceIfNew(device);
        }
      }
    } catch (e) {
      print('⚠️ خطأ في البحث عن خدمات WebSocket: $e');
    }
  }

  /// البحث عن خدمات ESP32 مخصصة
  Future<void> _searchForEsp32Services(Duration timeout) async {
    try {
      await for (final PtrResourceRecord record in _mdnsClient
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.service('_esp32._tcp'),
            timeout: timeout,
          )
          .timeout(timeout, onTimeout: () async* {})) {
        
        final device = await _parseServiceRecord(record.domainName);
        if (device != null) {
          _addDeviceIfNew(device);
        }
      }
    } catch (e) {
      print('⚠️ خطأ في البحث عن خدمات ESP32: $e');
    }
  }

  /// استخراج معلومات الجهاز من سجل mDNS
  Future<EspDevice?> _parseServiceRecord(String domainName) async {
    try {
      // البحث عن سجل A (عنوان IP)
      final addresses = await _mdnsClient
          .lookup<AResourceRecord>(
            ResourceRecordQuery.addressRecord(domainName),
          )
          .toList();

      if (addresses.isEmpty) return null;

      final ipAddress = addresses.first.address.host;
      
      // البحث عن سجل SRV (البورت والمعلومات)
      final srvRecords = await _mdnsClient
          .lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(domainName),
          )
          .toList();

      final port = srvRecords.isNotEmpty ? srvRecords.first.port : 8080;

      // محاولة جلب البيانات من الجهاز
      return await _fetchDeviceInfo(ipAddress, port);
    } catch (e) {
      print('⚠️ خطأ في استخراج المعلومات: $e');
      return null;
    }
  }

  /// جلب معلومات الجهاز من الـ API
  Future<EspDevice?> _fetchDeviceInfo(String ipAddress, int port) async {
    try {
      final url = Uri.parse('http://$ipAddress:$port/api/info');
      
      final response = await HttpClient()
          .getUrl(url)
          .timeout(const Duration(seconds: 5))
          .then((request) => request.close())
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final jsonData = await response
          .transform(utf8.decoder)
          .join()
          .then((data) => json.decode(data) as Map<String, dynamic>);

      return _parseDeviceJson(jsonData, ipAddress, port);
    } catch (e) {
      // إذا فشلت الاتصال، إنشاء جهاز أساسي
      return _createBasicDevice(ipAddress, port);
    }
  }

  /// تحليل بيانات الجهاز من JSON
  EspDevice? _parseDeviceJson(
    Map<String, dynamic> json,
    String ipAddress,
    int port,
  ) {
    try {
      final relays = (json['relays'] as List<dynamic>?)
              ?.map((r) => Relay.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [];

      final sensors = (json['sensors'] as List<dynamic>?)
              ?.map((s) => Sensor.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [];

      return EspDevice(
        id: json['id'] as String? ?? ipAddress,
        name: json['name'] as String? ?? 'جهاز ESP32',
        location: json['location'] as String? ?? 'غير محدد',
        localPin: json['pin'] as String? ?? '1234',
        ownerId: 'local_user',
        ipAddress: ipAddress,
        port: port,
        status: 'connected',
        isDemo: false,
        relays: relays,
        sensors: sensors,
        deviceType: 'ESP32',
        firmwareVersion: json['version'] as String?,
      );
    } catch (e) {
      print('❌ خطأ في تحليل البيانات: $e');
      return null;
    }
  }

  /// إنشاء جهاز أساسي بدون بيانات
  EspDevice _createBasicDevice(String ipAddress, int port) {
    return EspDevice(
      id: ipAddress,
      name: 'جهاز ESP32',
      location: 'غير محدد',
      localPin: '1234',
      ownerId: 'local_user',
      ipAddress: ipAddress,
      port: port,
      status: 'connected',
      isDemo: false,
    );
  }

  // ============================================================================
  // إدارة القائمة
  // ============================================================================

  /// إضافة جهاز إلى القائمة إذا لم يكن موجوداً
  void _addDeviceIfNew(EspDevice device) {
    if (!_discoveredDevices.any((d) => d.id == device.id)) {
      _discoveredDevices.add(device);
      print('✅ وجدت جهاز: ${device.name} (${device.ipAddress})');
    }
  }

  /// الحصول على الأجهزة المكتشفة
  List<EspDevice> getDiscoveredDevices() => List.from(_discoveredDevices);

  /// البث المباشر للأجهزة المكتشفة
  Stream<List<EspDevice>> get devicesStream => _devicesStreamController.stream;

  /// البحث المستمر عن الأجهزة
  void startContinuousDiscovery({
    Duration interval = const Duration(seconds: 30),
  }) {
    _discoverySubscription?.cancel();
    _discoverySubscription = Stream.periodic(interval).listen((_) async {
      await discoverDevices();
    });
  }

  /// إيقاف البحث المستمر
  void stopContinuousDiscovery() {
    _discoverySubscription?.cancel();
  }

  // ============================================================================
  // اختبار الاتصال
  // ============================================================================

  /// اختبار الاتصال بجهاز
  Future<bool> testConnection(EspDevice device) async {
    try {
      if (device.ipAddress == null) return false;

      final url = Uri.parse('${device.connectionUrl}/ping');
      final response = await HttpClient()
          .getUrl(url)
          .timeout(const Duration(seconds: 5))
          .then((request) => request.close());

      return response.statusCode == 200;
    } catch (e) {
      print('❌ فشل اختبار الاتصال: $e');
      return false;
    }
  }

  /// الحصول على حالة الاتصال
  Future<Map<String, dynamic>> getDeviceStatus(EspDevice device) async {
    try {
      if (device.ipAddress == null) return {'connected': false};

      final url = Uri.parse('${device.connectionUrl}/api/status');
      final response = await HttpClient()
          .getUrl(url)
          .timeout(const Duration(seconds: 5))
          .then((request) => request.close());

      if (response.statusCode != 200) {
        return {'connected': false};
      }

      final jsonData = await response
          .transform(utf8.decoder)
          .join()
          .then((data) => json.decode(data) as Map<String, dynamic>);

      return {
        'connected': true,
        ...jsonData,
      };
    } catch (e) {
      print('❌ خطأ في جلب الحالة: $e');
      return {'connected': false};
    }
  }
}

// استيراد المكتبات المطلوبة
import 'dart:convert' as json;
import 'dart:convert';