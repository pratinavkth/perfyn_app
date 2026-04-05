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

  /// Deserializes a Supabase row into a [TransactionRecord].
  ///
  /// Throws [FormatException] when any required field (id, user_id, amount,
  /// type, date, created_at) is missing or unparseable.
  /// Optional fields (category, notes) use sensible defaults.
  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw FormatException('Missing or empty "id" in transaction row', json);
    }

    final userId = json['user_id'] as String?;
    if (userId == null || userId.isEmpty) {
      throw FormatException('Missing or empty "user_id" in transaction row', json);
    }

    final rawAmount = json['amount'];
    if (rawAmount == null || rawAmount is! num) {
      throw FormatException('Missing or non-numeric "amount" in transaction row', json);
    }

    final rawType = json['type'] as String?;
    if (rawType == null || (rawType != 'income' && rawType != 'expense')) {
      throw FormatException('Missing or unknown "type" ("$rawType") in transaction row', json);
    }

    final rawDate = json['date'] as String?;
    final parsedDate = rawDate != null ? DateTime.tryParse(rawDate) : null;
    if (parsedDate == null) {
      throw FormatException('Missing or unparseable "date" ("$rawDate") in transaction row', json);
    }

    final rawCreatedAt = json['created_at'] as String?;
    final parsedCreatedAt = rawCreatedAt != null ? DateTime.tryParse(rawCreatedAt) : null;
    if (parsedCreatedAt == null) {
      throw FormatException('Missing or unparseable "created_at" ("$rawCreatedAt") in transaction row', json);
    }

    return TransactionRecord(
      id: id,
      userId: userId,
      amount: rawAmount.toDouble(),
      type: rawType == 'income' ? TransactionType.income : TransactionType.expense,
      category: json['category'] as String? ?? 'Other',
      date: parsedDate,
      notes: json['notes'] as String?,
      createdAt: parsedCreatedAt,
    );
  }
}
