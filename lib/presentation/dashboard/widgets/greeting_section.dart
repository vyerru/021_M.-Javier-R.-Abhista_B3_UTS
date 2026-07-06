import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/user.dart';

class GreetingSection extends StatelessWidget {
  final User? user;
  final bool isDark;

  const GreetingSection({super.key, required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Selamat Pagi'
        : hour < 15
            ? 'Selamat Siang'
            : hour < 18
                ? 'Selamat Sore'
                : 'Selamat Malam';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting,',
                  style: TextStyle(fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(user?.fullName ?? 'Pengguna',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkText : AppTheme.primaryNavy,
                      letterSpacing: -0.5),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(user?.role.label ?? '',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppTheme.accentCyan, letterSpacing: 0.5)),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 26,
          backgroundColor: AppTheme.accentCyan.withValues(alpha: 0.15),
          backgroundImage: user?.avatarUrl.isNotEmpty == true
              ? NetworkImage(user!.avatarUrl)
              : null,
          child: user?.avatarUrl.isNotEmpty != true
              ? Text(user?.fullName.isNotEmpty == true
                  ? user!.fullName[0].toUpperCase()
                  : '?',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                      color: AppTheme.accentCyan))
              : null,
        ),
      ],
    );
  }
}
