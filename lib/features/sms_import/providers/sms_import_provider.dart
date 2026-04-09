import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfyn_app/features/sms_import/data/sms_reader_service.dart';
import 'package:perfyn_app/features/sms_import/domain/entities/parsed_sms_transaction.dart';
import 'package:perfyn_app/features/transactions/providers/transaction_provider.dart';

final smsReaderServiceProvider = Provider<SmsReaderService>((ref) {
  return SmsReaderService();
});

final smsImportProvider =
    StateNotifierProvider<SmsImportController, SmsImportState>((ref) {
      final service = ref.watch(smsReaderServiceProvider);
      return SmsImportController(ref, service);
    });

class SmsImportState {
  const SmsImportState({
    this.isLoading = false,
    this.isImporting = false,
    this.permissionDenied = false,
    this.error,
    this.items = const [],
    this.importedCount = 0,
  });

  final bool isLoading;
  final bool isImporting;
  final bool permissionDenied;
  final String? error;
  final List<ParsedSmsTransaction> items;
  final int importedCount;

  int get selectedCount => items.where((item) => item.isSelected).length;

  SmsImportState copyWith({
    bool? isLoading,
    bool? isImporting,
    bool? permissionDenied,
    String? error,
    bool clearError = false,
    List<ParsedSmsTransaction>? items,
    int? importedCount,
  }) {
    return SmsImportState(
      isLoading: isLoading ?? this.isLoading,
      isImporting: isImporting ?? this.isImporting,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      error: clearError ? null : (error ?? this.error),
      items: items ?? this.items,
      importedCount: importedCount ?? this.importedCount,
    );
  }
}

class SmsImportController extends StateNotifier<SmsImportState> {
  SmsImportController(this._ref, this._service) : super(const SmsImportState());

  final Ref _ref;
  final SmsReaderService _service;

  Future<void> loadMessages() async {
    state = state.copyWith(
      isLoading: true,
      permissionDenied: false,
      importedCount: 0,
      clearError: true,
    );

    try {
      final granted = await _service.requestPermission();
      if (!granted) {
        state = state.copyWith(
          isLoading: false,
          permissionDenied: true,
          error: 'SMS permission is required to scan bank alerts.',
          items: const [],
        );
        return;
      }

      final messages = await _service.readInboxMessages();
      final existingTransactions =
          _ref.read(transactionsProvider).valueOrNull ?? const [];
      final items = _service.parseMessages(
        messages,
        existingTransactions: existingTransactions,
      );

      state = state.copyWith(
        isLoading: false,
        items: items,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not read SMS messages on this device.',
        items: const [],
      );
    }
  }

  void toggleSelection(String id) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == id && item.canImport)
            item.copyWith(isSelected: !item.isSelected)
          else
            item,
      ],
    );
  }

  Future<int> importSelected() async {
    state = state.copyWith(isImporting: true, clearError: true);
    var imported = 0;

    try {
      for (final item in state.items.where((entry) => entry.isSelected && entry.canImport)) {
        final error = await _ref
            .read(transactionControllerProvider.notifier)
            .addTransaction(
              amount: item.amount,
              type: item.type,
              category: item.category,
              date: item.date,
              notes: _buildNotes(item),
            );

        if (error == null) {
          imported++;
        }
      }

      state = state.copyWith(
        isImporting: false,
        importedCount: imported,
        items: [
          for (final item in state.items)
            if (item.isSelected && item.canImport)
              item.copyWith(
                alreadyImported: true,
                isSelected: false,
              )
            else
              item,
        ],
      );
      return imported;
    } catch (_) {
      state = state.copyWith(
        isImporting: false,
        error: 'Import failed. Please try again.',
      );
      return imported;
    }
  }

  String _buildNotes(ParsedSmsTransaction item) {
    final parts = <String>[
      if (item.merchant != null && item.merchant!.isNotEmpty) item.merchant!,
      'Imported from SMS',
      if (item.accountMask != null) 'A/c ${item.accountMask}',
      'Sender ${item.sender}',
    ];
    return parts.join(' • ');
  }
}
