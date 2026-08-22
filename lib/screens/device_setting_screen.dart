library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../models/esp_device_model.dart';
import '../core/theme.dart';

/// شاشة إعدادات الجهاز
class DeviceSettingsScreen extends StatefulWidget {
  final EspDevice device;

  const DeviceSettingsScreen({
    super.key,
    required this.device,
  });

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _pinController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device.name);
    _locationController = TextEditingController(text: widget.device.location);
    _pinController = TextEditingController(text: widget.device.localPin);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الجهاز'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== Basic Info ====================
              _buildSectionHeader('المعلومات الأساسية'),
              const SizedBox(height: 12),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'اسم الجهاز',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'الموقع',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================== Security ====================
              _buildSectionHeader('الأمان'),
              const SizedBox(height: 12),

              TextField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور المحلية',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),

              const SizedBox(height: 24),

              // ==================== Connection Info ====================
              _buildSectionHeader('معلومات الاتصال'),
              const SizedBox(height: 12),

              _buildInfoRow(
                label: 'عنوان IP',
                value: widget.device.ipAddress ?? 'N/A',
              ),

              _buildInfoRow(
                label: 'البورت',
                value: '${widget.device.port ?? 8080}',
              ),

              _buildInfoRow(
                label: 'نوع الجهاز',
                value: widget.device.deviceType,
              ),

              _buildInfoRow(
                label: 'النسخة',
                value: widget.device.firmwareVersion ?? 'N/A',
              ),

              const SizedBox(height: 24),

              // ==================== Device Stats ====================
              _buildSectionHeader('الإحصائيات'),
              const SizedBox(height: 12),

              _buildInfoRow(
                label: 'عدد الروليهات',
                value: '${widget.device.relays.length}',
              ),

              _buildInfoRow(
                label: 'عدد الحساسات',
                value: '${widget.device.sensors.length}',
              ),

              _buildInfoRow(
                label: 'معرّف الجهاز',
                value: widget.device.id,
              ),

              const SizedBox(height: 24),

              // ==================== Actions ====================
              _buildSectionHeader('الإجراءات'),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('حفظ التغييرات'),
                onPressed: () => _saveChanges(context),
              ),

              const SizedBox(height: 8),

              OutlinedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('حذف الجهاز'),
                onPressed: () => _confirmDelete(context),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Builder Methods
  // ============================================================================

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
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

  void _saveChanges(BuildContext context) {
    final updatedDevice = widget.device.copyWith(
      name: _nameController.text,
      location: _locationController.text,
      localPin: _pinController.text,
    );

    context.read<DeviceProvider>().updateDevice(updatedDevice);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ التغييرات')),
    );

    Navigator.pop(context);
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الجهاز'),
        content: Text('هل تريد حذف "${widget.device.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DeviceProvider>().deleteDevice(widget.device.id);
              Navigator.pop(context);
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