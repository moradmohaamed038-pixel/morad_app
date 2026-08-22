library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/demo_mode_provider.dart';
import '../providers/cloud_sync_provider.dart';
import '../core/theme.dart';

/// شاشة اختيار الوضع
/// يختار المستخدم بين:
/// - Demo Mode (تجربة بدون أجهزة حقيقية)
/// - Local Mode (التحكم عبر الشبكة المحلية)
/// - Cloud Mode (التحكم من أي مكان عبر Firebase)
class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  late DeviceProvider deviceProvider;
  late DemoModeProvider demoProvider;
  late CloudSyncProvider cloudProvider;

  @override
  void initState() {
    super.initState();
    deviceProvider = context.read<DeviceProvider>();
    demoProvider = context.read<DemoModeProvider>();
    cloudProvider = context.read<CloudSyncProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر وضع التشغيل'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================== Header ====================
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.dashboard_customize_outlined,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'اختر كيفية التحكم بأجهزتك',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'يمكنك التبديل بين الأوضاع في أي وقت',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ==================== Demo Mode Card ====================
              _buildModeCard(
                icon: Icons.videogame_asset_outlined,
                title: 'الوضع الافتراضي',
                subtitle: 'Demo Mode',
                description: 'جرّب التطبيق بدون أجهزة حقيقية\nواجهة كاملة مع بيانات وهمية',
                color: Colors.blue,
                onTap: () => _selectDemoMode(),
              ),

              const SizedBox(height: 16),

              // ==================== Local Mode Card ====================
              _buildModeCard(
                icon: Icons.router_outlined,
                title: 'الوضع المحلي',
                subtitle: 'Local Mode',
                description: 'تحكم مباشر عبر الشبكة المحلية\nأسرع وأكثر موثوقية',
                color: Colors.green,
                onTap: () => _selectLocalMode(),
              ),

              const SizedBox(height: 16),

              // ==================== Cloud Mode Card ====================
              _buildModeCard(
                icon: Icons.cloud_outlined,
                title: 'الوضع السحابي',
                subtitle: 'Cloud Mode',
                description: 'تحكم من أي مكان عبر Firebase\nمع تزامن تام بين الأجهزة',
                color: Colors.orange,
                onTap: () => _selectCloudMode(),
              ),

              const SizedBox(height: 40),

              // ==================== Info Box ====================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'معلومات',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الوضع الافتراضي يوفر تجربة كاملة بدون الحاجة لأجهزة حقيقية. '
                      'اختر الوضع المحلي إذا كان لديك أجهزة ESP32 على الشبكة. '
                      'الوضع السحابي يتطلب الاتصال بالإنترنت.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
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

  /// بناء بطاقة الوضع
  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Actions
  // ============================================================================

  /// اختيار الوضع الافتراضي
  void _selectDemoMode() {
    // إضافة جهاز افتراضي
    deviceProvider.addDemoDevice(advanced: false);

    // بدء المحاكاة
    demoProvider.startSimulation();

    // الذهاب للشاشة التالية
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  /// اختيار الوضع المحلي
  void _selectLocalMode() {
    // الذهاب لشاشة اكتشاف الأجهزة
    Navigator.of(context).pushNamed('/device_discovery');
  }

  /// اختيار الوضع السحابي
  void _selectCloudMode() {
    // بدء التزامن
    cloudProvider.startSync();

    // الذهاب لشاشة الأجهزة
    Navigator.of(context).pushReplacementNamed('/devices_list');
  }
}