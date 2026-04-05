import 'package:flutter/material.dart';
import 'package:perfyn_app/core/theme/app_colors.dart';

class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.chips,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5FBFF), Color(0xFFFFF6F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Builder(
                  builder: (context) {
                    return IconButton.filledTonal(
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                      icon: const Icon(Icons.person_outline_rounded),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140A2538),
                    blurRadius: 26,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: accent),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: chips
                        .map(
                          (chip) => Chip(
                            label: Text(chip),
                            backgroundColor: accent.withValues(alpha: 0.08),
                            side: BorderSide.none,
                            labelStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
