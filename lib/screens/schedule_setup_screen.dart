library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../models/relay_model.dart';
import '../models/schedule_model.dart';
import '../core/theme.dart';
import 'package:uuid/uuid.dart';

/// شاشة إعداد الجدولة
class ScheduleSetupScreen extends StatefulWidget {
  final Relay relay;

  const ScheduleSetupScreen({
    super.key,
    required this.relay,
  });

  @override
  State<ScheduleSetupScreen> createState() => _ScheduleSetupScreenState();
}

class _ScheduleSetupScreenState extends State<ScheduleSetupScreen> {
  late TextEditingController _nameController;
  late int _hour;
  late int _minute;
  late bool _targetState;
  late String _repeatType;
  late List<int> _selectedDays;

  final List<String> _repeatTypes = ['يومي', 'أسبوعي', 'مرة واحدة'];
  final List<String> _dayNames = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _hour = 12;
    _minute = 0;
    _targetState = !widget.relay.state;
    _repeatType = 'يومي';
    _selectedDays = [0, 1, 2, 3, 4, 5, 6]; // جميع الأيام
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('جدولة - ${widget.relay.name}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== Name ====================
              _buildSectionHeader('اسم الجدولة'),
              const SizedBox(height: 12),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'مثال: تشغيل المكيف صباحاً',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================== Time ====================
              _buildSectionHeader('الوقت'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildTimeSelector(
                      label: 'الساعة',
                      value: _hour,
                      max: 23,
                      onChanged: (value) {
                        setState(() => _hour = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeSelector(
                      label: 'الدقيقة',
                      value: _minute,
                      max: 59,
                      onChanged: (value) {
                        setState(() => _minute = value);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ==================== Repeat Type ====================
              _buildSectionHeader('نوع التكرار'),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                children: _repeatTypes.map((type) {
                  final isSelected = _repeatType == type;
                  return FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _repeatType = type);
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ==================== Days (إذا كان أسبوعي) ====================
              if (_repeatType == 'أسبوعي') ...[
                _buildSectionHeader('أيام التكرار'),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (index) {
                    final isSelected = _selectedDays.contains(index);
                    return FilterChip(
                      label: Text(_dayNames[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(index);
                          } else {
                            _selectedDays.remove(index);
                          }
                          _selectedDays.sort();
                        });
                      },
                    );
                  }),
                ),

                const SizedBox(height: 24),
              ],

              // ==================== Action ====================
              _buildSectionHeader('الإجراء'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_targetState ? Colors.green : Colors.red)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_targetState ? Colors.green : Colors.red)
                        .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _targetState ? 'تشغيل الروليه' : 'إيقاف الروليه',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _targetState ? Colors.green : Colors.red,
                      ),
                    ),
                    Switch(
                      value: _targetState,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      onChanged: (value) {
                        setState(() => _targetState = value);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ==================== Buttons ====================

              ElevatedButton.icon(
                icon: const Icon(Icons.schedule),
                label: const Text('حفظ الجدولة'),
                onPressed: () => _saveSchedule(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
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

  Widget _buildTimeSelector({
    required String label,
    required int value,
    required int max,
    required Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (value > 0) onChanged(value - 1);
                },
                splashRadius: 20,
              ),
              Text(
                value.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (value < max) onChanged(value + 1);
                },
                splashRadius: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // Actions
  // ============================================================================

  void _saveSchedule(BuildContext context) {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل اسم الجدولة')),
      );
      return;
    }

    // إنشاء جدولة
    final schedule = RelaySchedule(
      id: const Uuid().v4(),
      relayId: widget.relay.id,
      deviceId: context.read<DeviceProvider>().activeDevice?.id ?? '',
      name: _nameController.text,
      targetState: _targetState,
      hour: _hour,
      minute: _minute,
      repeatType: _repeatType == 'يومي'
          ? 'daily'
          : _repeatType == 'أسبوعي'
              ? 'weekly'
              : 'once',
      repeatDays: _selectedDays,
    );

    // حفظ الجدولة
    // (سيتم التنفيذ حسب متطلبات التطبيق)

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ الجدولة: ${_nameController.text}'),
      ),
    );

    Navigator.pop(context);
  }
}