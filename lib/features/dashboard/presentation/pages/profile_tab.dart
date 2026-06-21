import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uts_1123150004/core/constants/app_colors.dart';
import 'package:uts_1123150004/core/routes/app_router.dart';
import 'package:uts_1123150004/features/auth/presentation/providers/auth_provider.dart';

class ProfileTab extends StatelessWidget {
  final String name;
  final String email;

  const ProfileTab({super.key, required this.name, required this.email});

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
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
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
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),

          // Menu Informasi Profil
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
            ),
            child: Column(
              children: [
                _buildProfileItem(
                  icon: Icons.person_outline,
                  title: 'Nama Lengkap',
                  value: name,
                ),
                const Divider(height: 1, indent: 56),
                _buildProfileItem(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  value: email,
                ),
                const Divider(height: 1, indent: 56),
                _buildProfileItem(
                  icon: Icons.security_rounded,
                  title: 'Status Akun',
                  value: 'Terverifikasi (Firebase)',
                  trailing: const Icon(Icons.verified, color: Colors.blue, size: 20),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Menu Aksi Tambahan
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
            ),
            child: Column(
              children: [
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
