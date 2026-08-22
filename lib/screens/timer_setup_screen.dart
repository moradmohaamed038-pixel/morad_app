library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../models/relay_model.dart';
import '../models/timer_model.dart';
import '../core/theme.dart';
import 'package:uuid/uuid.dart';

/// شاشة إعداد المؤقتات
class TimerSetupScreen extends StatefulWidget {
  final Relay relay;

  const TimerSetupScreen({
    super.key,
    required this.relay,
  });

  @override
  State<TimerSetupScreen> createState() => _TimerSetupScreenState();
}

class _TimerSetupScreenState extends State<TimerSetupScreen> {
  late int _durationMinutes;
  late bool _targetState;

  @override
  void initState() {
    super.initState();
    _durationMinutes = 1;
    _targetState = !widget.relay.state; // عكس الحالة الحالية
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مؤقت - ${widget.relay.name}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================== Header ====================
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'تعيين مؤقت',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'سيتم ${_targetState ? 'تشغيل' : 'إيقاف'} الروليه '
                      'بعد $_durationMinutes دقيقة',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ==================== Duration Selector ====================
              _buildSectionHeader('المدة'),

              const SizedBox(height: 16),

              // عرض المدة الكبير
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_durationMinutes',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'دقيقة',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Slider لتعديل المدة
              Slider(
                value: _durationMinutes.toDouble(),
                min: 1,
                max: 120,
                divisions: 119,
                label: '$_durationMinutes دقيقة',
                onChanged: (value) {
                  setState(() => _durationMinutes = value.toInt());
                },
              ),

              // أزرار سريعة
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickButton(1),
                    _buildQuickButton(5),
                    _buildQuickButton(10),
                    _buildQuickButton(15),
                    _buildQuickButton(30),
                    _buildQuickButton(60),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ==================== Target State ====================
              _buildSectionHeader('الإجراء المطلوب'),

              const SizedBox(height: 16),

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

              const SizedBox(height: 40),

              // ==================== Buttons ====================

              ElevatedButton.icon(
                icon: const Icon(Icons.timer),
                label: const Text('تعيين المؤقت'),
                onPressed: () => _setTimer(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
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

  Widget _buildQuickButton(int minutes) {
    final isSelected = _durationMinutes == minutes;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$minutes دقيقة'),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _durationMinutes = minutes);
          }
        },
      ),
    );
  }

  // ============================================================================
  // Actions
  // ============================================================================

  void _setTimer(BuildContext context) {
    // إنشاء مؤقت
    final timer = RelayTimer(
      id: const Uuid().v4(),
      relayId: widget.relay.id,
      deviceId: context.read<DeviceProvider>().activeDevice?.id ?? '',
      targetState: _targetState,
      durationMinutes: _durationMinutes,
    );

    // تشغيل المؤقت
    context.read<DeviceProvider>().toggleRelayWithTimer(
          relayId: widget.relay.id,
          durationMinutes: _durationMinutes,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم تعيين مؤقت $_durationMinutes دقيقة',
        ),
      ),
    );

    Navigator.pop(context);
  }
}