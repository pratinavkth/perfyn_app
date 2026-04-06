import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:perfyn_app/core/theme/app_colors.dart';
import 'package:perfyn_app/features/transactions/domain/entities/transaction_record.dart';
import 'package:perfyn_app/features/transactions/providers/transaction_provider.dart';
import 'package:perfyn_app/shared/extensions/currency_extension.dart';
import 'package:perfyn_app/features/transactions/presentation/add_edit_transaction_screen.dart';

class CategoryDrillScreen extends ConsumerWidget {
  const CategoryDrillScreen({super.key, required this.category});

  static const routePath = '/category-drill';
  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5FBFF),
      appBar: AppBar(
        title: Text(
          '$category drill-down',
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
        child: transactionsAsync.when(
          data: (items) {
            final filteredItems = items
                .where((item) => item.category == category)
                .toList();

            if (filteredItems.isEmpty) {
              return Center(
                child: Text(
                  'No transactions found for $category.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.slate,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DrillDownTile(item: item),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Could not load transactions',
              style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.coral),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrillDownTile extends StatelessWidget {
  const _DrillDownTile({required this.item});

  final TransactionRecord item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = '${item.date.day}/${item.date.month}/${item.date.year}';

    return InkWell(
      onTap: () {
        context.pushNamed(
          'add-edit-transaction',
          extra: item,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080A2538),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.isExpense
                    ? AppColors.coral.withValues(alpha: 0.1)
                    : AppColors.mint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.isExpense ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: item.isExpense ? AppColors.coral : AppColors.mint,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.notes?.isNotEmpty == true ? item.notes! : dateStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.slate,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              item.amount.toINR(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: item.isExpense ? AppColors.ink : AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
