import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:perfyn_app/core/theme/app_colors.dart';
import 'package:perfyn_app/features/sms_import/presentation/sms_import_sheet.dart';
import 'package:perfyn_app/features/transactions/domain/entities/transaction_record.dart';
import 'package:perfyn_app/features/transactions/presentation/add_edit_transaction_screen.dart';
import 'package:perfyn_app/features/transactions/presentation/quick_add_sheet.dart';
import 'package:perfyn_app/features/transactions/providers/transaction_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  static const routePath = '/transactions';

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Income', 'Expense'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
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
                                'View, search, and manage your entries.',
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
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by category or notes...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Income', 'Expense'].map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedFilter = filter);
                                }
                              },
                              backgroundColor: Colors.white,
                              selectedColor: AppColors.ocean.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.ocean : AppColors.slate,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? AppColors.ocean : AppColors.ink.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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
                            'Quick actions',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Capture a transaction manually or pull likely bank alerts from SMS for review.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.slate,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    QuickAddSheet.show(context);
                                  },
                                  icon: const Icon(Icons.flash_on_rounded),
                                  label: const Text('Quick add'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    SmsImportSheet.show(context);
                                  },
                                  icon: const Icon(Icons.sms_rounded),
                                  label: const Text('Import SMS'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                sliver: transactionsAsync.when(
                  data: (items) {
                    final filteredItems = items.where((item) {
                      if (_selectedFilter == 'Income' && item.isExpense) return false;
                      if (_selectedFilter == 'Expense' && !item.isExpense) return false;
                      if (_searchQuery.isNotEmpty) {
                        final searchMatch = item.category.toLowerCase().contains(_searchQuery) ||
                            (item.notes?.toLowerCase().contains(_searchQuery) ?? false);
                        if (!searchMatch) return false;
                      }
                      return true;
                    }).toList();

                    return SliverToBoxAdapter(
                      child: _TransactionList(items: filteredItems),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: _StatusCard(
                      title: 'Loading transactions...',
                      subtitle: 'Reading from your Supabase table.',
                    ),
                  ),
                  error: (error, _) => SliverToBoxAdapter(
                    child: _StatusCard(
                      title: 'Could not load transactions',
                      subtitle: error.toString(),
                    ),
                  ),
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
              'No transactions found.',
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

class _TransactionRow extends ConsumerWidget {
  const _TransactionRow({
    required this.item,
  });

  final TransactionRecord item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = item.isExpense ? AppColors.coral : AppColors.success;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.coral,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text('Are you sure you want to delete this transaction?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.coral),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        ref.read(transactionControllerProvider.notifier).deleteTransaction(
              localId: item.localId!,
              remoteId: item.id.startsWith('local_') ? null : item.id,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.notes?.trim().isNotEmpty == true ? item.notes!.trim() : item.category} deleted.',
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            context.push(AddEditTransactionScreen.routePath, extra: item);
          },
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
        ),
      ),
    );
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
    return '${date.day} ${months[date.month - 1]}';
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
