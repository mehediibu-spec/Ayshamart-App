import 'package:intl/intl.dart';

/// Renders prices with the Bangladeshi Taka sign (৳, U+09F3) accurately and
/// consistently across the app — product cards, cart, totals and discount
/// math. WooCommerce returns prices as strings (e.g. "1499.00"); we parse
/// defensively and format with thousands separators.
///
/// Important: the Taka sign ৳ is a Bengali-script glyph. It only renders if
/// the active text style uses a font that contains it (Hind Siliguri / Noto
/// Sans Bengali do). The app theme sets such a font globally, so prefer the
/// plain symbol over the "Tk"/"BDT" fallback.
class Taka {
  const Taka._();

  static const String symbol = '৳'; // ৳

  static final NumberFormat _decimal = NumberFormat('#,##0.##', 'en_US');
  static final NumberFormat _whole = NumberFormat('#,##0', 'en_US');

  /// Parse a WooCommerce price string/num into a double. Returns 0 on failure.
  static double toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final cleaned = value.toString().replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  /// Format an amount as "৳1,499" (whole) or "৳1,499.50" when it has paisa.
  static String format(dynamic value, {bool forceDecimals = false}) {
    final amount = toDouble(value);
    final hasFraction = amount % 1 != 0;
    final formatted = (forceDecimals || hasFraction)
        ? _decimal.format(amount)
        : _whole.format(amount);
    return '$symbol$formatted';
  }

  /// Format in Bengali numerals, e.g. "৳১,৪৯৯". Used when locale == bn.
  static String formatBengali(dynamic value, {bool forceDecimals = false}) {
    final ascii = format(value, forceDecimals: forceDecimals);
    return _toBengaliDigits(ascii);
  }

  /// Locale-aware formatter — Bengali digits for `bn`, ASCII otherwise.
  static String formatForLocale(dynamic value, String localeCode,
      {bool forceDecimals = false}) {
    return localeCode == 'bn'
        ? formatBengali(value, forceDecimals: forceDecimals)
        : format(value, forceDecimals: forceDecimals);
  }

  /// Whole-percentage discount between a regular and sale price, e.g. 25.
  static int discountPercent(dynamic regular, dynamic sale) {
    final r = toDouble(regular);
    final s = toDouble(sale);
    if (r <= 0 || s <= 0 || s >= r) return 0;
    return (((r - s) / r) * 100).round();
  }

  static const List<String> _bnDigits = [
    '০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯',
  ];

  static String _toBengaliDigits(String input) {
    final buffer = StringBuffer();
    for (final codeUnit in input.runes) {
      if (codeUnit >= 0x30 && codeUnit <= 0x39) {
        buffer.write(_bnDigits[codeUnit - 0x30]);
      } else {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }
}
