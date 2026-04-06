import 'package:intl/intl.dart';

extension CurrencyFormat on num {
  /// Formats a number to Indian Rupees (e.g. ₹ 15,000)
  /// Includes decimals only if the number has a fractional part.
  String toINR() {
    final hasDecimal = this % 1 != 0;
    
    // Always insert a space after the rupee symbol for visual breathing room
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: hasDecimal ? 2 : 0,
    );
    return format.format(this);
  }

  /// Formats a number to a compact Indian Rupee representation (e.g. ₹ 15K, ₹ 1.5Cr)
  String toCompactINR() {
    final format = NumberFormat.compactCurrency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 0,
    );
    return format.format(this);
  }
}
