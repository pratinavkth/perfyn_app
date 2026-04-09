import 'package:another_telephony/telephony.dart';
import 'package:perfyn_app/features/transactions/domain/entities/transaction_record.dart';
import 'package:perfyn_app/features/sms_import/domain/entities/parsed_sms_transaction.dart';

class SmsReaderService {
  SmsReaderService({Telephony? telephony})
    : _telephony = telephony ?? Telephony.instance;

  final Telephony _telephony;

  Future<bool> requestPermission() async {
    final granted = await _telephony.requestSmsPermissions;
    return granted ?? false;
  }

  Future<List<SmsMessage>> readInboxMessages() async {
    return _telephony.getInboxSms();
  }

  List<ParsedSmsTransaction> parseMessages(
    List<SmsMessage> messages, {
    required List<TransactionRecord> existingTransactions,
  }) {
    final parsed = <ParsedSmsTransaction>[];

    for (final message in messages) {
      final item = _parseMessage(
        message,
        existingTransactions: existingTransactions,
      );
      if (item != null) {
        parsed.add(item);
      }
    }

    parsed.sort((a, b) => b.date.compareTo(a.date));
    return parsed.take(40).toList();
  }

  ParsedSmsTransaction? _parseMessage(
    SmsMessage message, {
    required List<TransactionRecord> existingTransactions,
  }) {
    final body = message.body?.trim();
    if (body == null || body.isEmpty) return null;

    final normalized = body.toLowerCase();
    final type = _detectType(normalized);
    if (type == null) return null;

    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) return null;

    final sender = (message.address ?? 'Unknown').trim();
    final date = message.date != null
        ? DateTime.fromMillisecondsSinceEpoch(message.date!)
        : DateTime.now();
    final accountMask = _extractAccountMask(body);
    final merchant = _extractMerchant(body);
    final category = _suggestCategory(normalized, type);
    final reasons = <String>[];
    var score = 0;

    if (_isTrustedSender(sender)) {
      score += 3;
      reasons.add('Known sender');
    } else {
      score -= 3;
      reasons.add('Unknown sender');
    }

    if (accountMask != null) {
      score += 2;
      reasons.add('Account detected');
    } else {
      reasons.add('No account found');
    }

    score += 2;
    reasons.add(type == TransactionType.expense ? 'Debit pattern' : 'Credit pattern');

    if (_looksStructured(normalized)) {
      score += 2;
      reasons.add('Structured bank message');
    }

    if (_hasSuspiciousTerms(normalized)) {
      score -= 4;
      reasons.add('Suspicious wording');
    }

    final trustLevel = score >= 6
        ? SmsTrustLevel.trusted
        : score >= 3
        ? SmsTrustLevel.review
        : SmsTrustLevel.suspicious;

    final alreadyImported = existingTransactions.any((transaction) {
      return transaction.type == type &&
          (transaction.amount - amount).abs() < 0.01 &&
          transaction.date.year == date.year &&
          transaction.date.month == date.month &&
          transaction.date.day == date.day;
    });

    if (alreadyImported) {
      reasons.add('Already imported');
    }

    return ParsedSmsTransaction(
      id: (message.id ?? date.microsecondsSinceEpoch).toString(),
      amount: amount,
      type: type,
      messageBody: body,
      date: date,
      trustLevel: trustLevel,
      accountMask: accountMask,
      merchant: merchant,
      sender: sender,
      category: category,
      reasonTags: reasons,
      isSelected: !alreadyImported && trustLevel != SmsTrustLevel.suspicious,
      alreadyImported: alreadyImported,
    );
  }

  TransactionType? _detectType(String body) {
    if (body.contains('debited') ||
        body.contains('spent') ||
        body.contains('withdrawn') ||
        body.contains('purchase')) {
      return TransactionType.expense;
    }
    if (body.contains('credited') ||
        body.contains('received') ||
        body.contains('deposited') ||
        body.contains('refund')) {
      return TransactionType.income;
    }
    return null;
  }

  double? _extractAmount(String body) {
    final match = RegExp(
      r'(?:rs\.?|inr)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    ).firstMatch(body);
    final raw = match?.group(1)?.replaceAll(',', '');
    return raw == null ? null : double.tryParse(raw);
  }

  String? _extractAccountMask(String body) {
    final patterns = [
      RegExp(r'(?:a/c|acct|account)\s*(?:no\.?|ending|xx)?\s*[*xX-]*\s*(\d{3,6})', caseSensitive: false),
      RegExp(r'xx(\d{3,6})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      final digits = match?.group(1);
      if (digits != null && digits.isNotEmpty) {
        return digits;
      }
    }
    return null;
  }

  String? _extractMerchant(String body) {
    final patterns = [
      RegExp(r'(?:at|to)\s+([A-Za-z0-9&._ -]{3,30})', caseSensitive: false),
      RegExp(r'upi(?:\s*ref.*)?\s+to\s+([A-Za-z0-9&._ -]{3,30})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      final merchant = match?.group(1)?.trim();
      if (merchant != null && merchant.isNotEmpty) {
        return merchant;
      }
    }
    return null;
  }

  bool _isTrustedSender(String sender) {
    final normalized = sender.toUpperCase();
    const trustedFragments = [
      'HDFC',
      'ICICI',
      'SBI',
      'AXIS',
      'KOTAK',
      'IDFC',
      'HSBC',
      'PNB',
      'BOB',
      'CANARA',
      'UNION',
      'YES',
      'INDUS',
      'PAYTM',
      'AIRTEL',
    ];

    return trustedFragments.any(normalized.contains);
  }

  bool _looksStructured(String body) {
    return (body.contains('a/c') || body.contains('acct') || body.contains('account')) &&
        (body.contains('rs') || body.contains('inr'));
  }

  bool _hasSuspiciousTerms(String body) {
    const suspiciousTerms = [
      'click here',
      'call now',
      'kyc blocked',
      'verify immediately',
      'account suspended',
      'http',
      'www',
    ];

    return suspiciousTerms.any(body.contains);
  }

  String _suggestCategory(String body, TransactionType type) {
    if (type == TransactionType.income) {
      if (body.contains('salary')) return 'Salary';
      if (body.contains('refund')) return 'Refund';
      if (body.contains('interest')) return 'Investment';
      return 'Other';
    }

    if (body.contains('restaurant') || body.contains('food') || body.contains('swiggy') || body.contains('zomato')) {
      return 'Food';
    }
    if (body.contains('uber') || body.contains('ola') || body.contains('metro') || body.contains('fuel')) {
      return 'Travel';
    }
    if (body.contains('amazon') || body.contains('flipkart') || body.contains('myntra')) {
      return 'Shopping';
    }
    if (body.contains('electricity') || body.contains('bill') || body.contains('recharge')) {
      return 'Bills';
    }
    if (body.contains('movie') || body.contains('netflix') || body.contains('spotify')) {
      return 'Entertainment';
    }
    if (body.contains('apollo') || body.contains('pharmacy') || body.contains('hospital')) {
      return 'Health';
    }
    return 'Bills';
  }
}
