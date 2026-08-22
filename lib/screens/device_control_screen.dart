library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/demo_mode_provider.dart';
import '../providers/local_connection_provider.dart';
import '../models/relay_model.dart';
import '../models/sensor_model.dart';
import '../core/theme.dart';

/// شاشة التحكم بالجهاز
/// عرض وتحكم الروليهات والحساسات
class DeviceControlScreen extends StatefulWidget {
  const DeviceControlScreen({super.key});

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  @override
  void initState() {
    super.initState();
    // تحديث الحالة عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceProvider>().refreshRelaysStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<DeviceProvider>(
          builder: (context, provider, _) {
            return Text(provider.activeDevice?.name ?? 'لا يوجد جهاز');
          },
        ),
        centerTitle: true,
        actions: [
          // حالة الاتصال
          Consumer<DeviceProvider>(
            builder: (context, provider, _) {
              final isConnected = provider.isConnected;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Tooltip(
                    message: isConnected ? 'متصل' : 'غير متصل',
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color:
                            isConnected ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // قائمة الخيارات
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('إعادة تحميل'),
                onTap: () {
                  context.read<DeviceProvider>().refreshRelaysStatus();
                },
              ),
              PopupMenuItem(
                child: const Text('الإعدادات'),
                onTap: () {
                  Navigator.pushNamed(context, '/device_settings');
                },
              ),
              PopupMenuItem(
                child: const Text('قائمة الأجهزة'),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/devices_list');
                },
              ),
              PopupMenuItem(
                child: const Text('تغيير الوضع'),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/mode_selection');
                },
              ),
            ],
          ),
        ],
      ),
      body: Consumer2<DeviceProvider, LocalConnectionProvider>(
        builder: (context, deviceProvider, localProvider, _) {
          final device = deviceProvider.activeDevice;

          if (device == null) {
            return const Center(
              child: Text('لا يوجد جهاز مختار'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => deviceProvider.refreshRelaysStatus(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات الجهاز
                    _buildDeviceInfo(device),
                    const SizedBox(height: 24),

                    // الروليهات
                    if (device.hasRelays) ...[
                      _buildSectionHeader('الروليهات'),
                      _buildRelaysList(context, device.relays),
                      const SizedBox(height: 24),
                    ],

                    // الحساسات
                    if (device.hasSensors) ...[
                      _buildSectionHeader('الحساسات'),
                      _buildSensorsList(device.sensors),
                      const SizedBox(height: 24),
                    ],

                    // رسالة خطأ إن وجدت
                    if (deviceProvider.errorMessage != null)
                      _buildErrorBanner(deviceProvider.errorMessage!),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================================
  // Builder Methods
  // ============================================================================

  /// معلومات الجهاز
  Widget _buildDeviceInfo(device) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.router,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      device.location,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: device.isConnected
                      ? Colors.green.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  device.isConnected ? 'متصل' : 'معطل',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: device.isConnected ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                label: 'الروليهات',
                value: '${device.relays.length}',
              ),
              _buildInfoItem(
                label: 'الحساسات',
                value: '${device.sensors.length}',
              ),
              _buildInfoItem(
                label: 'النسخة',
                value: device.firmwareVersion ?? 'N/A',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// عنصر المعلومة
  Widget _buildInfoItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// رأس القسم
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// قائمة الروليهات
  Widget _buildRelaysList(BuildContext context, List<Relay> relays) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: relays.length,
      itemBuilder: (context, index) {
        final relay = relays[index];
        return _buildRelayCard(context, relay);
      },
    );
  }

  /// بطاقة الروليه
  Widget _buildRelayCard(BuildContext context, Relay relay) {
    return GestureDetector(
      onLongPress: () {
        _showRelayOptions(context, relay);
      },
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: relay.state
                  ? AppTheme.primaryColor.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // الرمز والاسم
              Column(
                children: [
                  Text(
                    relay.icon ?? '⚡',
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    relay.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // الحالة والزر
              Row(
                children: [
                  Expanded(
                    child: Text(
                      relay.state ? 'مشغل' : 'معطل',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            relay.state ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: relay.state,
                      onChanged: (value) {
                        context.read<DeviceProvider>().toggleRelay(
                              relay.id,
                              value,
                            );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// قائمة الحساسات
  Widget _buildSensorsList(List<Sensor> sensors) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sensors.length,
      itemBuilder: (context, index) {
        final sensor = sensors[index];
        return _buildSensorCard(sensor);
      },
    );
  }

  /// بطاقة الحساس
  Widget _buildSensorCard(Sensor sensor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // الرمز
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (sensor.color != null
                        ? Color(int.parse('0xff${sensor.color!.replaceFirst('#', '')}'))
                        : AppTheme.primaryColor)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                sensor.icon ?? '📊',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 12),

            // المعلومات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sensor.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sensor.description ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // القيمة
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${sensor.value.toStringAsFixed(1)}${sensor.unit}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (sensor.warningThreshold != null &&
                    sensor.value > sensor.warningThreshold!)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          size: 14,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'تحذير',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// رسالة الخطأ
  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Actions
  // ============================================================================

  /// خيارات الروليه
  void _showRelayOptions(BuildContext context, Relay relay) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              relay.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.timer),
              label: const Text('تشغيل بمؤقت'),
              onPressed: () {
                Navigator.pop(context);
                _showTimerDialog(context, relay);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.schedule),
              label: const Text('جدولة'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/schedule_setup',
                  arguments: relay,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// حوار المؤقت
  void _showTimerDialog(BuildContext context, Relay relay) {
    int minutes = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('تشغيل بمؤقت'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الروليه: ${relay.name}'),
              const SizedBox(height: 16),
              Text(
                'المدة: $minutes دقيقة',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: minutes.toDouble(),
                min: 1,
                max: 60,
                divisions: 59,
                label: '$minutes',
                onChanged: (value) {
                  setState(() => minutes = value.toInt());
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<DeviceProvider>().toggleRelayWithTimer(
                  relayId: relay.id,
                  durationMinutes: minutes,
                );
                Navigator.pop(context);
              },
              child: const Text('تشغيل'),
            ),
          ],
        ),
      ),
    );
  }
}