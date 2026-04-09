import 'package:flutter/material.dart';
import 'package:perfyn_app/core/theme/app_colors.dart';
import 'package:perfyn_app/shared/constants/categories.dart';
import 'package:perfyn_app/shared/widgets/pressable_scale.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final TransactionCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? category.color.withValues(alpha: 0.16) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? category.color.withValues(alpha: 0.7)
                : AppColors.ink.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category.icon,
                size: 18,
                color: category.color,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              category.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
