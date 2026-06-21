import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uts_1123150004/core/routes/app_router.dart';
import 'package:uts_1123150004/core/services/biometric_service.dart';
import 'package:uts_1123150004/core/widgets/auth_header.dart';
import 'package:uts_1123150004/core/widgets/custom_button.dart';
import 'package:uts_1123150004/core/widgets/custom_text_field.dart';
import 'package:uts_1123150004/core/widgets/divider_with_text.dart';
import 'package:uts_1123150004/core/widgets/google_sign_in_button.dart';
import 'package:uts_1123150004/core/widgets/loading_overlay.dart';
import 'package:uts_1123150004/features/auth/presentation/providers/auth_provider.dart';




class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;

  final BiometricService _biometricService = BiometricService();
  bool _showBiometricButton = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricEnabled();
    final credentials = await _biometricService.getSavedCredentials();
    if (mounted) {
      setState(() {
        _showBiometricButton = available && enabled && credentials != null;
      });
      // Auto-prompt biometrics if enabled and credentials saved
      if (available && enabled && credentials != null) {
        _loginBiometric();
      }
    }
  }

  Future<void> _loginBiometric() async {
    final authenticated = await _biometricService.authenticate();
    if (!authenticated) return;

    final credentials = await _biometricService.getSavedCredentials();
    if (credentials == null) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithEmail(
      email: credentials['email']!,
      password: credentials['password']!,
    );

    if (!mounted) return;
    _handleLoginResult(ok, auth);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// Handler untuk login email/password
  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    
    final ok = await auth.loginWithEmail(
      email: email,
      password: password,
    );

    if (!mounted) return;
    if (ok) {
      // Save credentials for biometric login helper
      await _biometricService.saveCredentials(email, password);
    }
    _handleLoginResult(ok, auth);
  }

  /// Handler untuk login Google
  Future<void> _loginGoogle() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithGoogle();
    if (!mounted) return;
    _handleLoginResult(ok, auth);
  }

  /// Routing berdasarkan hasil login
  void _handleLoginResult(bool ok, AuthProvider auth) {
    if (ok) {
      Navigator.pushReplacementNamed(context, AppRouter.dashboard);
    } else if (auth.status == AuthStatus.emailNotVerified) {
      Navigator.pushReplacementNamed(context, AppRouter.verifyEmail);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Login gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Password'),
        content: CustomTextField(
          label: 'Email',
          hint: 'Email terdaftar',
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          // ElevatedButton(
          //   onPressed: () async {
          //     await Fire.instance.sendPasswordResetEmail(
          //       email: ctrl.text.trim(),
          //     );
          //     if (context.mounted) Navigator.pop(context);
          //   },
          //   child: const Text('Kirim'),
          // ),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Masuk ke akun...',
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  const AuthHeader(
                    icon: Icons.sports_soccer,
                    title: 'Selamat Datang',
                    subtitle: 'Masuk ke akun Anda untuk melanjutkan',
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    label: 'Email',
                    hint: 'contoh@email.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Email wajib diisi';
                      if (!EmailValidator.validate(v!)) {
                        return 'Format email salah';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Password',
                    hint: 'Masukkan password',
                    controller: _passCtrl,
                    obscureText: !_showPass,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPass ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _showPass = !_showPass),
                    ),
                    validator: (v) =>
                        (v?.isEmpty ?? true) ? 'Password wajib diisi' : null,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showForgotPasswordDialog(context),
                      child: const Text('Lupa Password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'Masuk',
                          onPressed: _loginEmail,
                          isLoading: isLoading,
                        ),
                      ),
                      if (_showBiometricButton) ...[
                        const SizedBox(width: 12),
                        Container(
                          height: 52,
                          width: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200, width: 1.5),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.fingerprint_rounded, size: 28, color: Color(0xFF4CAF50)),
                            onPressed: _loginBiometric,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  const DividerWithText(text: 'atau masuk dengan'),
                  const SizedBox(height: 20),
                  GoogleSignInButton(
                    onPressed: _loginGoogle,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun? '),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          AppRouter.register,
                        ),
                        child: const Text(
                          'Daftar',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
