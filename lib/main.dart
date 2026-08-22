library;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/firebase_init_service.dart';
import 'core/theme.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/mode_selection_screen.dart';
import 'screens/devices_list_screen.dart';
import 'screens/device_discovery_screen.dart';
import 'screens/device_control_screen.dart';
import 'screens/device_settings_screen.dart';
import 'screens/timer_setup_screen.dart';
import 'screens/schedule_setup_screen.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/device_provider.dart';
import 'providers/local_connection_provider.dart';
import 'providers/demo_mode_provider.dart';
import 'providers/cloud_sync_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/analytics_provider.dart';

// Models
import 'models/relay_model.dart';
import 'models/esp_device_model.dart';

// ============================================================================
// Main Entry Point
// ============================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ تهيئة Firebase - الخطوة الأولى الحرجة
    print('🔥 تهيئة Firebase...');
    await FirebaseInitService.initialize();

    print('✅ Firebase جاهزة');

    // ✅ تشغيل التطبيق
    runApp(const MoradTkApp());
  } catch (e) {
    print('❌ خطأ في بدء التطبيق: $e');
    // عرض شاشة خطأ
    runApp(const ErrorApp());
  }
}

// ============================================================================
// Main App
// ============================================================================

class MoradTkApp extends StatelessWidget {
  const MoradTkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ============================================================================
        // Providers غير غيّرة الحالة (Services)
        // ============================================================================

        Provider<FirebaseInitService>(
          create: (_) => FirebaseInitService(),
        ),

        // ============================================================================
        // Providers غيّرة الحالة (ChangeNotifiers)
        // ============================================================================

        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => DeviceProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => LocalConnectionProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => DemoModeProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => CloudSyncProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => NotificationsProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => AnalyticsProvider(),
        ),
      ],
      child: MaterialApp(
        // ============================================================================
        // Configuration
        // ============================================================================

        title: 'MORAD_TK',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],

        // ============================================================================
        // Initial Route
        // ============================================================================

        home: const SplashScreen(),

        // ============================================================================
        // Named Routes
        // ============================================================================

        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/mode_selection': (context) => const ModeSelectionScreen(),
          '/devices_list': (context) => const DevicesListScreen(),
          '/device_discovery': (context) => const DeviceDiscoveryScreen(),
          '/device_control': (context) => const DeviceControlScreen(),
        },

        // ============================================================================
        // Dynamic Routes
        // ============================================================================

        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/device_settings':
              final device = settings.arguments as EspDevice?;
              if (device == null) {
                return _errorRoute('لم يتم تمرير الجهاز');
              }
              return MaterialPageRoute(
                builder: (_) => DeviceSettingsScreen(device: device),
              );

            case '/timer_setup':
              final relay = settings.arguments as Relay?;
              if (relay == null) {
                return _errorRoute('لم يتم تمرير الروليه');
              }
              return MaterialPageRoute(
                builder: (_) => TimerSetupScreen(relay: relay),
              );

            case '/schedule_setup':
              final relay = settings.arguments as Relay?;
              if (relay == null) {
                return _errorRoute('لم يتم تمرير الروليه');
              }
              return MaterialPageRoute(
                builder: (_) => ScheduleSetupScreen(relay: relay),
              );

            default:
              return MaterialPageRoute(
                builder: (_) => const SplashScreen(),
              );
          }
        },

        // ============================================================================
        // Error Handler
        // ============================================================================

        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(TextScaler.linear(1.0)),
            child: child!,
          );
        },
      ),
    );
  }

  /// مسار خطأ
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('خطأ')),
        body: Center(child: Text(message)),
      ),
    );
  }
}

// ============================================================================
// Error App (إذا فشلت التهيئة)
// ============================================================================

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.withOpacity(0.1),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red[700],
                ),
                const SizedBox(height: 24),
                Text(
                  'خطأ في تهيئة التطبيق',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.red[700],
                      ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'تحقق من:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('✓ الاتصال بالإنترنت'),
                      Text('✓ ملف firebase_options.dart موجود'),
                      Text('✓ google-services.json في المكان الصحيح'),
                      Text('✓ لا توجد أخطاء في وحدة التحكم'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}