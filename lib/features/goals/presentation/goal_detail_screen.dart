import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:perfyn_app/core/theme/app_colors.dart';
import 'package:perfyn_app/features/goals/domain/entities/goal_record.dart';
import 'package:perfyn_app/features/goals/providers/goal_provider.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  const GoalDetailScreen({super.key, required this.goal});

  final GoalRecord goal;
  static const routePath = '/goals/detail';

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  late GoalRecord _goal;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
  }

  // A real app would refresh the individual goal from provider, but we'll use state for instant feedback.
  void _updateGoalProgress(double newAmount) {
    setState(() {
      _goal = GoalRecord(
        id: _goal.id,
        localId: _goal.localId,
        userId: _goal.userId,
        title: _goal.title,
        targetAmount: _goal.targetAmount,
        currentAmount: newAmount,
        type: _goal.type,
        createdAt: _goal.createdAt,
        deadline: _goal.deadline,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentForType(_goal.type);
    final isNoSpend = _goal.type == GoalType.noSpend;

    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: Text(
          'Goal Details',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral),
            onPressed: _confirmDelete,
            tooltip: 'Delete Goal',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Circular Progress
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: _goal.progress,
                      strokeWidth: 16,
                      backgroundColor: accent.withValues(alpha: 0.1),
                      color: accent,
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_iconForType(_goal.type), color: accent, size: 36),
                          const SizedBox(height: 12),
                          Text(
                            '${(_goal.progress * 100).toStringAsFixed(0)}%',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            isNoSpend ? 'Complete' : 'Saved',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.slate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Details Card
            Container(
              padding: const EdgeInsets.all(24),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _goal.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _subtitleForGoal(_goal),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: isNoSpend ? 'Current Day' : 'Current Amount',
                    value: _goal.formattedCurrent,
                    valueColor: accent,
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: isNoSpend ? 'Target Days' : 'Target Amount',
                    value: _goal.formattedTarget,
                  ),
                  if (_goal.daysRemaining != null) ...[
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'Time Remaining',
                      value: '${_goal.daysRemaining} days left',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Update Progress Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _showUpdateProgressDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ocean,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.add_task_rounded),
                label: Text(
                  isNoSpend ? 'Log Another Day' : 'Add Progress',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUpdateProgressDialog() async {
    final controller = TextEditingController();
    bool isAdding = true;

    if (_goal.type == GoalType.noSpend) {
      // For no-spend, just add 1 day
      final newAmount = _goal.currentAmount + 1;
      _updateProgressCall(newAmount);
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Update Progress'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Add'),
                        selected: isAdding,
                        onSelected: (val) => setDialogState(() => isAdding = true),
                        selectedColor: AppColors.ocean.withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Subtract'),
                        selected: !isAdding,
                        onSelected: (val) => setDialogState(() => isAdding = false),
                        selectedColor: AppColors.coral.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final val = double.tryParse(controller.text);
                    if (val != null && val > 0) {
                      final newAmount = isAdding
                          ? _goal.currentAmount + val
                          : (_goal.currentAmount - val).clamp(0.0, double.infinity);
                      Navigator.of(context).pop();
                      _updateProgressCall(newAmount);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateProgressCall(double newAmount) async {
    final error = await ref.read(goalControllerProvider.notifier).updateProgress(
          localId: _goal.localId!,
          remoteId: _goal.id.startsWith('local_') ? null : _goal.id,
          currentAmount: newAmount,
        );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      _updateGoalProgress(newAmount);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress updated!')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal? This cannot be undone.'),
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

    if (confirm != true || !mounted) return;

    final error = await ref.read(goalControllerProvider.notifier).deleteGoal(
          _goal.localId!,
          _goal.id.startsWith('local_') ? null : _goal.id,
        );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.of(context).pop();
    }
  }

  Color _accentForType(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return AppColors.success;
      case GoalType.budget:
        return AppColors.ocean;
      case GoalType.noSpend:
        return AppColors.coral;
    }
  }

  IconData _iconForType(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return Icons.savings_rounded;
      case GoalType.budget:
        return Icons.account_balance_wallet_rounded;
      case GoalType.noSpend:
        return Icons.block_rounded;
    }
  }

  String _subtitleForGoal(GoalRecord goal) {
    switch (goal.type) {
      case GoalType.savings:
        return 'Savings goal';
      case GoalType.budget:
        return 'Budget limit';
      case GoalType.noSpend:
        return 'No-spend challenge';
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.slate,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueColor ?? AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
