enum TransactionType { income, expense }

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  bool get isExpense => type == TransactionType.expense;

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      type: (json['type'] as String?) == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      category: json['category'] as String? ?? 'Other',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      notes: json['notes'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
