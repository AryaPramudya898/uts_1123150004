import 'package:flutter/material.dart';
import 'package:uts_1123150004/core/constants/app_colors.dart';

class AuthHeader extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String title;
  final String subtitle;
  final Color? iconColor;

  const AuthHeader({
    super.key,
    this.icon,
    this.imagePath,
    required this.title,
    required this.subtitle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: imagePath != null
              ? Image.asset(
                  imagePath!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                )
              : Icon(
                  icon ?? Icons.sports_soccer,
                  size: 48,
                  color: iconColor ?? AppColors.primary,
                ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
