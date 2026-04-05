import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:perfyn_app/core/theme/app_colors.dart';
import 'package:perfyn_app/features/transactions/domain/entities/transaction_record.dart';
import 'package:perfyn_app/features/transactions/presentation/quick_add_sheet.dart';
import 'package:perfyn_app/features/transactions/providers/transaction_provider.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  static const routePath = '/transactions';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5FBFF), Color(0xFFFFF6F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.refresh(transactionsProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transactions',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Live entries from your Supabase table, with quick add ready from here or the global FAB.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                      ],
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
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF4E7), Color(0xFFF0FAFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.ink.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick add flow',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Capture amount, type, category, date, and optional notes, then the list below refreshes from Supabase.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () {
                        QuickAddSheet.show(context);
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Open quick add'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              transactionsAsync.when(
                data: (items) => _TransactionList(items: items),
                loading: () => const _StatusCard(
                  title: 'Loading transactions...',
                  subtitle: 'Reading from your Supabase table.',
                ),
                error: (error, _) => _StatusCard(
                  title: 'Could not load transactions',
                  subtitle: error.toString(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.items});

  final List<TransactionRecord> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140A2538),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All transactions',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(
              'No transactions yet. Add your first one and it will appear here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.slate,
              ),
            )
          else
            ...items.map((item) => _TransactionRow(item: item)),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.item,
  });

  final TransactionRecord item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = item.isExpense ? AppColors.coral : AppColors.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              item.isExpense ? Icons.south_east_rounded : Icons.north_east_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.notes?.trim().isNotEmpty == true ? item.notes!.trim() : item.category,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.category} • ${_formatDate(item.date)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.isExpense ? '- ' : '+ '}Rs ${item.amount.toStringAsFixed(0)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140A2538),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
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
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
