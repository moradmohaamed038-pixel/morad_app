library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';

/// شاشة تسجيل الدخول
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLogin = true; // true: دخول، false: تسجيل
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ==================== Header ====================
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.router,
                              size: 48,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'MORAD_TK',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLogin
                                ? 'قم بتسجيل الدخول'
                                : 'إنشاء حساب جديد',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ==================== Form ====================
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // البريد الإلكتروني
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              hintText: 'example@email.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) => _email = value,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'البريد مطلوب';
                              }
                              if (!value!.contains('@')) {
                                return 'البريد غير صحيح';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // كلمة المرور
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showPassword = !_showPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            obscureText: !_showPassword,
                            onChanged: (value) => _password = value,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'كلمة المرور مطلوبة';
                              }
                              if (value!.length < 6) {
                                return 'كلمة المرور قصيرة جداً';
                              }
                              return null;
                            },
                          ),

                          // نسيان كلمة المرور (فقط في الدخول)
                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  _showForgotPasswordDialog(context);
                                },
                                child: const Text('نسيت كلمة المرور؟'),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================== Buttons ====================

                    // زر الدخول/التسجيل الرئيسي
                    ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () => _handleSubmit(context, authProvider),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(_isLogin ? 'دخول' : 'إنشاء حساب'),
                    ),

                    const SizedBox(height: 12),

                    // دخول مجهول
                    OutlinedButton.icon(
                      icon: const Icon(Icons.person_outline),
                      label: const Text('دخول مجهول'),
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              final success =
                                  await authProvider.anonymousLogin();
                              if (success && mounted) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/mode_selection',
                                );
                              }
                            },
                    ),

                    const SizedBox(height: 24),

                    // ==================== Toggle ====================

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin
                              ? 'ليس لديك حساب؟'
                              : 'لديك حساب بالفعل؟',
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _isLogin = !_isLogin);
                            _formKey.currentState?.reset();
                          },
                          child: Text(
                            _isLogin ? 'سجل الآن' : 'دخول',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ==================== Error Message ====================
                    if (authProvider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
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
                                  authProvider.errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Actions
  // ============================================================================

  void _handleSubmit(BuildContext context, AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    bool success;

    if (_isLogin) {
      success = await authProvider.login(
        email: _email,
        password: _password,
      );
    } else {
      success = await authProvider.register(
        email: _email,
        password: _password,
        displayName: _email.split('@')[0],
      );
    }

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/mode_selection');
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين كلمة المرور'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني',
            hintText: 'example@email.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().resetPassword(
                    emailController.text,
                  );
              Navigator.pop(context);
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }
}