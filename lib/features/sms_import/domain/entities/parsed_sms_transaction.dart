import 'package:perfyn_app/features/transactions/domain/entities/transaction_record.dart';

enum SmsTrustLevel { trusted, review, suspicious }

class ParsedSmsTransaction {
  const ParsedSmsTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.messageBody,
    required this.date,
    required this.trustLevel,
    required this.sender,
    required this.category,
    required this.isSelected,
    required this.alreadyImported,
    this.accountMask,
    this.merchant,
    this.reasonTags = const [],
  });

  final String id;
  final double amount;
  final TransactionType type;
  final String messageBody;
  final DateTime date;
  final SmsTrustLevel trustLevel;
  final String? accountMask;
  final String? merchant;
  final String sender;
  final String category;
  final List<String> reasonTags;
  final bool isSelected;
  final bool alreadyImported;

  bool get isExpense => type == TransactionType.expense;

  bool get canImport => !alreadyImported && trustLevel != SmsTrustLevel.suspicious;

  ParsedSmsTransaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? messageBody,
    DateTime? date,
    SmsTrustLevel? trustLevel,
    String? accountMask,
    String? merchant,
    String? sender,
    String? category,
    List<String>? reasonTags,
    bool? isSelected,
    bool? alreadyImported,
  }) {
    return ParsedSmsTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      messageBody: messageBody ?? this.messageBody,
      date: date ?? this.date,
      trustLevel: trustLevel ?? this.trustLevel,
      accountMask: accountMask ?? this.accountMask,
      merchant: merchant ?? this.merchant,
      sender: sender ?? this.sender,
      category: category ?? this.category,
      reasonTags: reasonTags ?? this.reasonTags,
      isSelected: isSelected ?? this.isSelected,
      alreadyImported: alreadyImported ?? this.alreadyImported,
    );
  }
}
