import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfyn_app/app/providers/app_providers.dart';
import 'package:perfyn_app/core/database/database_provider.dart';
import 'package:perfyn_app/core/network/sync_manager.dart';
import 'package:perfyn_app/features/auth/providers/auth_provider.dart';
import 'package:perfyn_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:perfyn_app/features/transactions/data/transaction_repository.dart';
import 'package:perfyn_app/features/transactions/domain/entities/transaction_record.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final dao = ref.watch(appDatabaseProvider).transactionsDao;
  final syncManager = ref.watch(syncManagerProvider);
  return TransactionRepository(client, dao, syncManager);
});

final transactionsProvider = StreamProvider.autoDispose<List<TransactionRecord>>((ref) {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    return const Stream.empty();
  }

  final repository = ref.watch(transactionRepositoryProvider);
  
  // Also kick off a background sync from server when someone watches this stream
  repository.syncFromServer(session.user.id).catchError((_) {});

  return repository.watchTransactions(session.user.id);
});

/// Controller for quick-add mutations.
/// Not autoDispose — survives async Supabase calls that outlive the calling widget.
final transactionControllerProvider =
    StateNotifierProvider<TransactionController, AsyncValue<void>>((ref) {
      final repository = ref.watch(transactionRepositoryProvider);
      return TransactionController(ref, repository);
    });

class TransactionController extends StateNotifier<AsyncValue<void>> {
  TransactionController(this._ref, this._repository) : super(const AsyncData(null));

  final Ref _ref;
  final TransactionRepository _repository;

  Future<String?> addTransaction({
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

  Future<String?> updateTransaction({
    required int localId,
    required String? remoteId,
    required double amount,
    required TransactionType type,
    required String category,
    required DateTime date,
    String? notes,
  }) async {
    final session = _ref.read(currentSessionProvider);
    if (session == null) {
      return 'You need to sign in before updating a transaction.';
    }

    state = const AsyncLoading();

    try {
      await _repository.updateTransaction(
        localId: localId,
        remoteId: remoteId,
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
      return 'Could not update the transaction. Please try again.';
    }
  }

  Future<String?> deleteTransaction({required int localId, required String? remoteId}) async {
    final session = _ref.read(currentSessionProvider);
    if (session == null) {
      return 'You need to sign in before deleting a transaction.';
    }

    state = const AsyncLoading();

    try {
      await _repository.deleteTransaction(
        localId: localId,
        remoteId: remoteId,
        userId: session.user.id,
      );

      state = const AsyncData(null);
      _ref.invalidate(transactionsProvider);
      _ref.invalidate(dashboardOverviewProvider);
      return null;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return 'Could not delete the transaction. Please try again.';
    }
  }
}
