import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uts_1123150004/core/constants/app_colors.dart';
import 'package:uts_1123150004/core/routes/app_router.dart';
import 'package:uts_1123150004/core/services/biometric_service.dart';
import 'package:uts_1123150004/features/auth/presentation/providers/auth_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Small delay to let splash animation be visible
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    
    // Check if session is persisted
    final isLoggedIn = await auth.checkPersistedSession();
    if (!isLoggedIn) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.login);
      }
      return;
    }

    // Check biometric settings
    final bioAvailable = await _biometricService.isBiometricAvailable();
    final bioEnabled = await _biometricService.isBiometricEnabled();

    if (bioAvailable && bioEnabled) {
      final authenticated = await _biometricService.authenticate();
      if (authenticated) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRouter.dashboard);
        }
      } else {
        // Biometrics failed/cancelled, route to login page
        // Set state to unauthenticated so the guard rejects direct dashboard access
        auth.setUnauthenticated();
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRouter.login);
        }
      }
    } else {
      // Biometrics not enabled/supported, proceed straight to dashboard
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.dashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sports_soccer,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sepatu Futsal Store',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aplikasi E-Commerce Sepatu Futsal Terbaik',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
