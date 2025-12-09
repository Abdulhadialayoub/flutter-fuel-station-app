import 'package:intl/intl.dart';

/// Utility class for formatting numbers and dates in Arabic locale
class ArabicFormatter {
  /// Format a number with Arabic locale
  /// 
  /// Example: 1234.56 -> ١٬٢٣٤٫٥٦
  static String formatNumber(double number, {int decimalDigits = 2}) {
    final formatter = NumberFormat.decimalPattern('ar');
    formatter.minimumFractionDigits = decimalDigits;
    formatter.maximumFractionDigits = decimalDigits;
    return formatter.format(number);
  }

  /// Format currency with Arabic locale
  /// 
  /// Example: 1234.56, 'ل.س' -> ١٬٢٣٤٫٥٦ ل.س
  static String formatCurrency(double amount, String currency, {int decimalDigits = 2}) {
    final formattedNumber = formatNumber(amount, decimalDigits: decimalDigits);
    return '$formattedNumber $currency';
  }

  /// Format date with Arabic locale
  static String formatDate(DateTime date) {
    final formatter = DateFormat.yMMMd('ar');
    return formatter.format(date);
  }

  /// Format time with Arabic locale
  static String formatTime(DateTime time) {
    final formatter = DateFormat.jm('ar');
    return formatter.format(time);
  }

  /// Format date and time with Arabic locale
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat.yMMMd('ar').add_jm();
    return formatter.format(dateTime);
  }
}
