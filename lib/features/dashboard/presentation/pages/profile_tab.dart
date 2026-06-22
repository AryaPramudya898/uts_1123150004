import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uts_1123150004/core/constants/app_colors.dart';
import 'package:uts_1123150004/core/routes/app_router.dart';
import 'package:uts_1123150004/core/services/secure_storage.dart';
import 'package:uts_1123150004/core/services/biometric_service.dart';
import 'package:uts_1123150004/features/auth/presentation/providers/auth_provider.dart';

class ProfileTab extends StatefulWidget {
  final String name;
  final String email;

  const ProfileTab({super.key, required this.name, required this.email});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final BiometricService _biometricService = BiometricService();
  bool _biometricEnabled = false;
  bool _isBiometricSupported = false;
  bool _isLoading = true;
  bool _isWalletConnected = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
    _loadWalletStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isBiometricSupported = available;
        _biometricEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWalletStatus() async {
    final connected = await SecureStorage.isWalletConnected();
    if (mounted) {
      setState(() {
        _isWalletConnected = connected;
      });
    }
  }

  Future<void> _onToggleBiometric(bool value) async {
    if (value) {
      // Prompt biometric authentication to enable it
      final authenticated = await _biometricService.authenticate();
      if (authenticated) {
        await _biometricService.setBiometricEnabled(true);
        setState(() {
          _biometricEnabled = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login biometrik berhasil diaktifkan'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } else {
        setState(() {
          _biometricEnabled = false;
        });
      }
    } else {
      await _biometricService.setBiometricEnabled(false);
      setState(() {
        _biometricEnabled = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login biometrik dinonaktifkan'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _toggleWalletConnection() async {
    if (_isWalletConnected) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Putuskan Dompet?'),
          content: const Text('Apakah Anda yakin ingin memutuskan hubungan akun dengan Coach E-Money?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Putuskan'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await SecureStorage.setWalletConnected(false);
        setState(() {
          _isWalletConnected = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hubungan Coach E-Money diputuskan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } else {
      final bool isInstalled = await canLaunchUrl(Uri.parse('dompetkampus://pay'));

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/icons/logo.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isInstalled ? 'Hubungkan Coach E-Money' : 'Instal Coach E-Money',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                isInstalled
                    ? 'Aplikasi Coach E-Money ditemukan di perangkat Anda. Hubungkan sekarang untuk mempermudah transaksi secara instan.'
                    : 'Aplikasi Coach E-Money belum terpasang di perangkat Anda. Silakan unduh terlebih dahulu untuk menikmati kemudahan pembayaran instan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (isInstalled) {
                      // Open the e-money app via deep link
                      await launchUrl(Uri.parse('dompetkampus://pay'), mode: LaunchMode.externalApplication);
                      
                      // Simulate loading and connect
                      showDialog(
                        context: this.context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: Card(
                            margin: EdgeInsets.all(32),
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: AppColors.primary),
                                  SizedBox(height: 16),
                                  Text(
                                    'Menghubungkan ke Coach E-Money...',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                      await Future.delayed(const Duration(seconds: 2));
                      if (this.mounted) {
                        Navigator.pop(this.context);
                        await SecureStorage.setWalletConnected(true);
                        setState(() {
                          _isWalletConnected = true;
                        });
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Berhasil terhubung ke Coach E-Money!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    } else {
                      // Suggest download - redirect to Play Store search or mock download page
                      await launchUrl(
                        Uri.parse('https://play.google.com/store/apps'),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isInstalled ? 'Masuk dengan Coach E-Money' : 'Unduh Coach E-Money',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          // User Avatar Circle
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 3),
              ),
              child: Center(
                child: Text(
                  widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // User Name with verified checkmark
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.verified,
                color: Colors.blue,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),

          // Hubungkan Akun ke Wallet
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
            ),
            child: _buildWalletItem(),
          ),

          const SizedBox(height: 24),

          // Menu Aksi Tambahan & Pengaturan
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
            ),
            child: Column(
              children: [
                _buildToggleItem(
                  icon: Icons.fingerprint_rounded,
                  title: 'Login Biometrik',
                  subtitle: _isBiometricSupported
                      ? 'Gunakan sidik jari/wajah untuk masuk'
                      : 'Biometrik tidak didukung di perangkat ini',
                  value: _biometricEnabled,
                  onChanged: _isBiometricSupported ? _onToggleBiometric : null,
                ),
                const Divider(height: 1, indent: 56),
                _buildActionItem(
                  icon: Icons.help_outline,
                  title: 'Hubungi Kami',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _buildActionItem(
                  icon: Icons.info_outline,
                  title: 'Tentang Aplikasi',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Tombol Logout Merah Premium
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Keluar dari Akun',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: () async {
                await auth.logout();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, AppRouter.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.shade100, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletItem() {
    return InkWell(
      onTap: _toggleWalletConnection,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _isWalletConnected ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/icons/logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 22,
                      color: _isWalletConnected ? AppColors.primary : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hubungkan dengan E-Money',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isWalletConnected ? 'Terhubung (Coach E-Money)' : 'Belum terhubung dengan e-money',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _isWalletConnected ? AppColors.primary : Colors.grey.shade400,
                      fontWeight: _isWalletConnected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _isWalletConnected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: _isWalletConnected ? AppColors.primary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.grey.shade600),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}
