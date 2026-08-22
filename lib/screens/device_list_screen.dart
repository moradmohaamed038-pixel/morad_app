library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../models/esp_device_model.dart';
import '../core/theme.dart';

/// شاشة قائمة الأجهزة
/// عرض وإدارة جميع الأجهزة المضافة
class DevicesListScreen extends StatefulWidget {
  const DevicesListScreen({super.key});

  @override
  State<DevicesListScreen> createState() => _DevicesListScreenState();
}

class _DevicesListScreenState extends State<DevicesListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأجهزة'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDeviceOptions(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DeviceProvider>().searchForDevices();
            },
          ),
        ],
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, deviceProvider, _) {
          // لا توجد أجهزة
          if (!deviceProvider.hasDevices) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: deviceProvider.devices.length,
            itemBuilder: (context, index) {
              final device = deviceProvider.devices[index];
              return _buildDeviceListItem(context, device, deviceProvider);
            },
          );
        },
      ),
    );
  }

  // ============================================================================
  // Builder Methods
  // ============================================================================

  /// حالة قائمة فارغة
  Widget _buildEmptyState(BuildContext context) {
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
              'لا توجد أجهزة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'أضف أول جهاز للبدء',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('إضافة جهاز'),
              onPressed: () => _showAddDeviceOptions(),
            ),
          ],
        ),
      ),
    );
  }

  /// عنصر الجهاز في القائمة
  Widget _buildDeviceListItem(
    BuildContext context,
    EspDevice device,
    DeviceProvider deviceProvider,
  ) {
    final isActive = deviceProvider.activeDevice?.id == device.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () async {
          // تعيين الجهاز كنشط
          await deviceProvider.setActiveDevice(device);

          if (mounted) {
            // الذهاب لشاشة التحكم
            Navigator.pushReplacementNamed(
              context,
              '/device_control',
            );
          }
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryColor.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.router,
            color: isActive ? AppTheme.primaryColor : Colors.grey,
          ),
        ),
        title: Text(
          device.name,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              device.location,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              device.isDemo
                  ? 'جهاز افتراضي'
                  : 'IP: ${device.ipAddress ?? 'N/A'}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // حالة الاتصال
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: device.isConnected ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // قائمة الخيارات
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('تعديل'),
                  onTap: () {
                    _showEditDeviceDialog(context, device, deviceProvider);
                  },
                ),
                PopupMenuItem(
                  child: const Text('الإعدادات'),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/device_settings',
                      arguments: device,
                    );
                  },
                ),
                PopupMenuItem(
                  child: const Text('حذف'),
                  onTap: () {
                    _showDeleteConfirmation(context, device, deviceProvider);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // Dialogs
  // ============================================================================

  /// خيارات إضافة جهاز
  void _showAddDeviceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'اختر طريقة الإضافة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('البحث عن أجهزة (محلي)'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/device_discovery');
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('إضافة يدوي'),
              onPressed: () {
                Navigator.pop(context);
                _showAddManuallyDialog();
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.videogame_asset),
              label: const Text('جهاز افتراضي (Demo)'),
              onPressed: () {
                context.read<DeviceProvider>().addDemoDevice(advanced: false);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
  }

  /// حوار الإضافة اليدوية
  void _showAddManuallyDialog() {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String ipAddress = '';
    String password = '1234';
    int port = 8080;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة جهاز يدوي'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'اسم الجهاز',
                    hintText: 'مثال: لوحة المطبخ',
                  ),
                  onChanged: (value) => name = value,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'عنوان IP',
                    hintText: '192.168.1.100',
                  ),
                  onChanged: (value) => ipAddress = value,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                  ),
                  onChanged: (value) => password = value,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'البورت',
                  ),
                  initialValue: '8080',
                  onChanged: (value) =>
                      port = int.tryParse(value) ?? 8080,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                // إضافة الجهاز
                // (سيتم التنفيذ بناءً على متطلبات التطبيق)
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  /// حوار تعديل الجهاز
  void _showEditDeviceDialog(
    BuildContext context,
    EspDevice device,
    DeviceProvider deviceProvider,
  ) {
    final formKey = GlobalKey<FormState>();
    String newName = device.name;
    String newLocation = device.location;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الجهاز'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: newName,
                decoration: const InputDecoration(labelText: 'اسم الجهاز'),
                onChanged: (value) => newName = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: newLocation,
                decoration: const InputDecoration(labelText: 'الموقع'),
                onChanged: (value) => newLocation = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              deviceProvider.renameDevice(device.id, newName);
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  /// تأكيد حذف الجهاز
  void _showDeleteConfirmation(
    BuildContext context,
    EspDevice device,
    DeviceProvider deviceProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الجهاز'),
        content: Text('هل تريد حذف "${device.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              deviceProvider.deleteDevice(device.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}