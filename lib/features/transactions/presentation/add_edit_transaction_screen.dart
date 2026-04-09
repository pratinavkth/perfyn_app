import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfyn_app/core/theme/app_colors.dart';
import 'package:perfyn_app/features/transactions/domain/entities/transaction_record.dart';
import 'package:perfyn_app/features/transactions/providers/transaction_provider.dart';
import 'package:perfyn_app/shared/constants/categories.dart';
import 'package:perfyn_app/shared/widgets/category_chip.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  const AddEditTransactionScreen({super.key, this.transaction});

  /// Navigates to this screen. Pass a transaction to edit it, or null to create a new one.
  final TransactionRecord? transaction;

  static const String routePath = '/transactions/add-edit';

  @override
  ConsumerState<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends ConsumerState<AddEditTransactionScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late TransactionType _type;
  late DateTime _selectedDate;
  String? _selectedCategory;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: _isEditing ? widget.transaction!.amount.toInt().toString() : '',
    );
    _noteController = TextEditingController(
      text: widget.transaction?.notes ?? '',
    );
    _type = widget.transaction?.isExpense == false
        ? TransactionType.income
        : TransactionType.expense;
    _selectedDate = widget.transaction?.date ?? DateTime.now();
    _selectedCategory = widget.transaction?.category;

    _amountController.addListener(_onFormUpdated);
  }

  void _onFormUpdated() {
    setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onFormUpdated);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<TransactionCategory> get _categories => _type == TransactionType.expense
      ? TransactionCategories.expense
      : TransactionCategories.income;

  bool get _isValid {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return false;
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return false;
    if (_selectedCategory == null) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submitState = ref.watch(transactionControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Transaction' : 'New Transaction',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral),
              onPressed: submitState.isLoading ? null : _confirmDelete,
              tooltip: 'Delete Transaction',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10324A), Color(0xFF1A6D86)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontWeight: FontWeight.w700,
                        ),
                        hintText: '0',
                        hintStyle: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontWeight: FontWeight.w900,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeSelectionButton(
                            title: 'Expense',
                            icon: Icons.south_east_rounded,
                            isSelected: _type == TransactionType.expense,
                            onTap: () {
                              setState(() {
                                _type = TransactionType.expense;
                                _selectedCategory = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TypeSelectionButton(
                            title: 'Income',
                            icon: Icons.north_east_rounded,
                            isSelected: _type == TransactionType.income,
                            onTap: () {
                              setState(() {
                                _type = TransactionType.income;
                                _selectedCategory = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Category',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categories
                    .map(
                      (category) => CategoryChip(
                        category: category,
                        isSelected: _selectedCategory == category.label,
                        onTap: () {
                          setState(() {
                            _selectedCategory = category.label;
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A0A2538),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.ocean.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.calendar_month_rounded, color: AppColors.ocean),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.slate,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(_selectedDate),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 32),
                    TextField(
                      controller: _noteController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'Add some details about this transaction',
                        filled: true,
                        fillColor: AppColors.cloud,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: submitState.isLoading || !_isValid ? null : _saveTransaction,
                  icon: submitState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    submitState.isLoading ? 'Saving...' : 'Save transaction',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    HapticFeedback.selectionClick();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    String? errorMessage;
    if (_isEditing) {
      final t = widget.transaction!;
      errorMessage = await ref.read(transactionControllerProvider.notifier).updateTransaction(
            localId: t.localId!,
            remoteId: t.id.startsWith('local_') ? null : t.id,
            amount: amount,
            type: _type,
            category: _selectedCategory!,
            date: _selectedDate,
            notes: _noteController.text,
          );
    } else {
      errorMessage = await ref.read(transactionControllerProvider.notifier).addTransaction(
            amount: amount,
            type: _type,
            category: _selectedCategory!,
            date: _selectedDate,
            notes: _noteController.text,
          );
    }

    if (!mounted) return;

    if (errorMessage != null) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? 'Transaction updated successfully.'
              : 'Transaction saved successfully.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
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

    if (confirm != true || !mounted || widget.transaction == null) return;

    final t = widget.transaction!;
    final errorMessage = await ref
        .read(transactionControllerProvider.notifier)
        .deleteTransaction(
          localId: t.localId!,
          remoteId: t.id.startsWith('local_') ? null : t.id,
        );

    if (!mounted) return;

    if (errorMessage != null) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction deleted successfully.')),
    );
    Navigator.of(context).pop();
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
}

class _TypeSelectionButton extends StatelessWidget {
  const _TypeSelectionButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
