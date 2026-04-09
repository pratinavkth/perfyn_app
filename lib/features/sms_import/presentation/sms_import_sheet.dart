import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:perfyn_app/core/theme/app_colors.dart';
import 'package:perfyn_app/features/sms_import/domain/entities/parsed_sms_transaction.dart';
import 'package:perfyn_app/features/sms_import/providers/sms_import_provider.dart';

class SmsImportSheet extends ConsumerStatefulWidget {
  const SmsImportSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SmsImportSheet(),
    );
  }

  @override
  ConsumerState<SmsImportSheet> createState() => _SmsImportSheetState();
}

class _SmsImportSheetState extends ConsumerState<SmsImportSheet> {
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoaded) return;
    _hasLoaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      HapticFeedback.selectionClick();
      await ref.read(smsImportProvider.notifier).loadMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(smsImportProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FBFD),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.slate.withValues(alpha: 0.26),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import from SMS',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Scan debit and credit alerts, review them, then import only the ones you trust.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.slate,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _InfoBanner(
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.ocean),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Messages are treated as suggestions. Suspicious or duplicate alerts are never auto-imported.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    if (state.isLoading) const _LoadingCard(),
                    if (!state.isLoading && state.error != null)
                      _MessageCard(
                        title: state.permissionDenied
                            ? 'Permission needed'
                            : 'Could not scan messages',
                        subtitle: state.error!,
                        icon: state.permissionDenied
                            ? Icons.sms_failed_outlined
                            : Icons.warning_amber_rounded,
                        actionLabel: 'Try again',
                        onAction: () async {
                          await ref.read(smsImportProvider.notifier).loadMessages();
                        },
                      ),
                    if (!state.isLoading &&
                        state.error == null &&
                        state.items.isEmpty)
                      _MessageCard(
                        title: 'No debit or credit messages found',
                        subtitle: 'Try again later or continue adding transactions manually.',
                        icon: Icons.mark_chat_unread_outlined,
                        actionLabel: 'Scan again',
                        onAction: () async {
                          await ref.read(smsImportProvider.notifier).loadMessages();
                        },
                      ),
                    if (state.items.isNotEmpty) ...[
                      _SummaryRow(state: state),
                      const SizedBox(height: 14),
                      ...state.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SmsImportTile(item: item),
                      )),
                    ],
                  ],
                ),
              ),
              if (state.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: state.isImporting
                              ? null
                              : () async {
                                  HapticFeedback.selectionClick();
                                  await ref.read(smsImportProvider.notifier).loadMessages();
                                },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Rescan'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: state.isImporting || state.selectedCount == 0
                              ? null
                              : () async {
                                  HapticFeedback.lightImpact();
                                  final imported = await ref
                                      .read(smsImportProvider.notifier)
                                      .importSelected();
                                  if (!context.mounted) return;
                                  if (imported > 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$imported transactions imported successfully.'),
                                      ),
                                    );
                                  }
                                },
                          icon: state.isImporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2.2),
                                )
                              : const Icon(Icons.download_done_rounded),
                          label: Text(
                            state.isImporting
                                ? 'Importing...'
                                : 'Import ${state.selectedCount} selected',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.state});

  final SmsImportState state;

  @override
  Widget build(BuildContext context) {
    final trusted = state.items
        .where((item) => item.trustLevel == SmsTrustLevel.trusted)
        .length;
    final review = state.items
        .where((item) => item.trustLevel == SmsTrustLevel.review)
        .length;
    final suspicious = state.items
        .where((item) => item.trustLevel == SmsTrustLevel.suspicious)
        .length;

    return Row(
      children: [
        Expanded(child: _MiniBadge(label: 'Trusted', value: trusted, color: AppColors.success)),
        const SizedBox(width: 10),
        Expanded(child: _MiniBadge(label: 'Review', value: review, color: AppColors.ocean)),
        const SizedBox(width: 10),
        Expanded(child: _MiniBadge(label: 'Suspicious', value: suspicious, color: AppColors.coral)),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.slate,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmsImportTile extends ConsumerWidget {
  const _SmsImportTile({required this.item});

  final ParsedSmsTransaction item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = item.isExpense ? AppColors.coral : AppColors.success;
    final trust = _trustPresentation(item.trustLevel);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.isSelected
            ? accent.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: item.isSelected
              ? accent.withValues(alpha: 0.45)
              : AppColors.ink.withValues(alpha: 0.08),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0A2538),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: item.canImport
            ? () {
                HapticFeedback.selectionClick();
                ref.read(smsImportProvider.notifier).toggleSelection(item.id);
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    item.isExpense
                        ? Icons.south_east_rounded
                        : Icons.north_east_rounded,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.isExpense ? '- ' : '+ '}Rs ${item.amount.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.category} • ${DateFormat('d MMM, h:mm a').format(item.date)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.alreadyImported)
                  const _StatePill(label: 'Imported', color: AppColors.slate)
                else
                  Checkbox(
                    value: item.isSelected,
                    onChanged: item.canImport
                        ? (_) {
                            HapticFeedback.selectionClick();
                            ref.read(smsImportProvider.notifier).toggleSelection(item.id);
                          }
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatePill(label: trust.$1, color: trust.$2),
                _StatePill(label: item.sender, color: AppColors.ocean),
                if (item.accountMask != null)
                  _StatePill(label: 'A/c ${item.accountMask}', color: AppColors.success),
              ],
            ),
            if (item.merchant != null) ...[
              const SizedBox(height: 10),
              Text(
                item.merchant!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              item.messageBody,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.slate,
                height: 1.4,
              ),
            ),
            if (item.reasonTags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: item.reasonTags
                    .take(3)
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.slate,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (String, Color) _trustPresentation(SmsTrustLevel level) {
    switch (level) {
      case SmsTrustLevel.trusted:
        return ('Trusted', AppColors.success);
      case SmsTrustLevel.review:
        return ('Review', AppColors.ocean);
      case SmsTrustLevel.suspicious:
        return ('Suspicious', AppColors.coral);
    }
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _MessageCard(
      title: 'Scanning your inbox...',
      subtitle: 'Looking for debit and credit alerts from banking messages.',
      icon: Icons.sync_rounded,
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.ocean, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.slate,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ocean.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}
