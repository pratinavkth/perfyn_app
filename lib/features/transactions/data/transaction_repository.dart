import 'package:perfyn_app/features/transactions/domain/entities/transaction_record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionRepository {
  const TransactionRepository(this._client);

  final SupabaseClient _client;

  Future<void> addTransaction({
    required String userId,
    required double amount,
    required TransactionType type,
    required String category,
    required DateTime date,
    String? notes,
  }) async {
    await _client.from('transactions').insert({
      'user_id': userId,
      'amount': amount,
      'type': type.name,
      'category': category,
      'date': _formatDate(date),
      'notes': notes?.trim().isEmpty ?? true ? null : notes?.trim(),
    });
  }

  Future<List<TransactionRecord>> fetchTransactions(String userId) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .order('created_at', ascending: false);

    return response
        .map<TransactionRecord>(
          (item) => TransactionRecord.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
