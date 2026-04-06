import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfyn_app/core/theme/app_colors.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const routePath = '/notifications';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5FBFF),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'TODAY',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.slate,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const _NotificationTile(
              title: 'Budget Alert',
              message: 'You have reached 90% of your Food budget for this month.',
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.coral,
              time: '2h ago',
              isUnread: true,
            ),
            const SizedBox(height: 12),
            const _NotificationTile(
              title: 'Streak Saver',
              message: 'You are on a 5-day No-Spend streak for Dining out! Keep it up!',
              icon: Icons.local_fire_department_rounded,
              iconColor: AppColors.mint,
              time: '5h ago',
              isUnread: true,
            ),
            const SizedBox(height: 32),
            Text(
              'THIS WEEK',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.slate,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const _NotificationTile(
              title: 'Goal Milestone',
              message: 'You reached 50% of your Emergency Fund goal!',
              icon: Icons.emoji_events_rounded,
              iconColor: AppColors.ocean,
              time: '2d ago',
              isUnread: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.time,
    required this.isUnread,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final String time;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: isUnread ? Border.all(color: AppColors.ocean.withValues(alpha: 0.2)) : null,
        boxShadow: [
          if (isUnread)
            const BoxShadow(
              color: Color(0x080A2538),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.slate,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.slate,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
