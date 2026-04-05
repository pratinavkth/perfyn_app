import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfyn_app/app/providers/app_providers.dart';
import 'package:perfyn_app/features/auth/providers/auth_provider.dart';
import 'package:perfyn_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:perfyn_app/features/transactions/data/transaction_repository.dart';
import 'package:perfyn_app/features/transactions/domain/entities/transaction_record.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TransactionRepository(client);
});

final transactionsProvider = FutureProvider.autoDispose<List<TransactionRecord>>((
  ref,
) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    return const [];
  }

  final repository = ref.watch(transactionRepositoryProvider);
  return repository.fetchTransactions(session.user.id);
});

final quickAddControllerProvider =
    StateNotifierProvider.autoDispose<QuickAddController, AsyncValue<void>>((ref) {
      final repository = ref.watch(transactionRepositoryProvider);
      return QuickAddController(ref, repository);
    });

class QuickAddController extends StateNotifier<AsyncValue<void>> {
  QuickAddController(this._ref, this._repository) : super(const AsyncData(null));

  final Ref _ref;
  final TransactionRepository _repository;

  Future<String?> submit({
    required double amount,
    required TransactionType type,
    required String category,
    required DateTime date,
    String? notes,
  }) async {
    final session = _ref.read(currentSessionProvider);
    if (session == null) {
      return 'You need to sign in before adding a transaction.';
    }

    state = const AsyncLoading();

    try {
      await _repository.addTransaction(
        userId: session.user.id,
        amount: amount,
        type: type,
        category: category,
        date: date,
        notes: notes,
      );

      state = const AsyncData(null);
      _ref.invalidate(transactionsProvider);
      _ref.invalidate(dashboardOverviewProvider);
      return null;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return 'Could not save the transaction to Supabase. Please try again.';
    }
  }
}
