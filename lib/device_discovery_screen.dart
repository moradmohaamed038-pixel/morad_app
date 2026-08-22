library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../models/esp_device_model.dart';
import '../core/theme.dart';

/// شاشة اكتشاف الأجهزة
/// البحث عن أجهزة ESP32 في الشبكة المحلية
class DeviceDiscoveryScreen extends StatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  State<DeviceDiscoveryScreen> createState() => _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState extends State<DeviceDiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    // بدء البحث تلقائياً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceProvider>().searchForDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اكتشف الأجهزة'),
        centerTitle: true,
        actions: [
          // زر إعادة البحث
          Consumer<DeviceProvider>(
            builder: (context, provider, _) {
              return provider.isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        provider.searchForDevices();
                      },
                    );
            },
          ),
        ],
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, deviceProvider, _) {
          // حالة البحث
          if (deviceProvider.isSearching) {
            return _buildSearchingState();
          }

          // حالة الخطأ
          if (deviceProvider.errorMessage != null) {
            return _buildErrorState(deviceProvider.errorMessage!);
          }

          // لم يتم العثور على أجهزة
          if (deviceProvider.discoveredDevices.isEmpty) {
            return _buildNoDevicesState();
          }

          // عرض الأجهزة المكتشفة
          return _buildDevicesList(deviceProvider);
        },
      ),
    );
  }

  // ============================================================================
  // Builder Methods
  // ============================================================================

  /// حالة البحث
  Widget _buildSearchingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جاري البحث عن الأجهزة...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى الانتظار (15 ثانية)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'تأكد من:\n'
              '• جهاز ESP32 مشغل\n'
              '• متصل بنفس الشبكة المحلية\n'
              '• WiFi مفعل على الهاتف',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// حالة الخطأ
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              'حدث خطأ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('حاول مرة أخرى'),
              onPressed: () {
                context.read<DeviceProvider>().searchForDevices();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// لا توجد أجهزة
  Widget _buildNoDevicesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_other_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'لم يتم العثور على أجهزة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'تأكد من أن أجهزة ESP32 مشغلة ومتصلة بالشبكة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('بحث جديد'),
                  onPressed: () {
                    context.read<DeviceProvider>().searchForDevices();
                  },
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.videogame_asset),
                  label: const Text('Demo'),
                  onPressed: () {
                    context.read<DeviceProvider>().addDemoDevice();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// قائمة الأجهزة المكتشفة
  Widget _buildDevicesList(DeviceProvider deviceProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: deviceProvider.discoveredDevices.length,
      itemBuilder: (context, index) {
        final device = deviceProvider.discoveredDevices[index];
        return _buildDeviceCard(context, device, deviceProvider);
      },
    );
  }

  /// بطاقة الجهاز
  Widget _buildDeviceCard(
    BuildContext context,
    EspDevice device,
    DeviceProvider deviceProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.router,
            color: AppTheme.primaryColor,
            size: 28,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'IP: ${device.ipAddress ?? 'N/A'}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              'الحالة: ${device.status}',
              style: TextStyle(
                color: device.isConnected ? Colors.green : Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () async {
            // إضافة الجهاز
            await deviceProvider.addDiscoveredDevice(device);

            // الاتصال بالجهاز
            await deviceProvider.setActiveDevice(device);

            if (mounted) {
              // الذهاب لشاشة التحكم
              Navigator.pushReplacementNamed(
                context,
                '/device_control',
              );
            }
          },
          child: const Text('اختر'),
        ),
      ),
    );
  }
}