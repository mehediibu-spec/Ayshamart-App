import 'package:ayshamart_app/core/utils/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Taka formatting', () {
    test('renders the ৳ sign with thousands separators', () {
      expect(Taka.format('1499.00'), '৳1,499');
      expect(Taka.format('169900'), '৳169,900');
      expect(Taka.format(169900), '৳169,900');
    });

    test('keeps paisa only when present', () {
      expect(Taka.format('1499.50'), '৳1,499.5');
      expect(Taka.format('1499.50', forceDecimals: true), '৳1,499.5');
      expect(Taka.format('1499'), '৳1,499');
    });

    test('parses messy WooCommerce strings safely', () {
      expect(Taka.toDouble('৳1,499.00'), 1499.0);
      expect(Taka.toDouble(null), 0);
      expect(Taka.toDouble('abc'), 0);
    });

    test('Bengali numerals', () {
      expect(Taka.formatBengali('1499'), '৳১,৪৯৯');
      expect(Taka.formatForLocale('1499', 'bn'), '৳১,৪৯৯');
      expect(Taka.formatForLocale('1499', 'en'), '৳1,499');
    });

    test('discount percentage', () {
      expect(Taka.discountPercent('184900', '169900'), 8);
      expect(Taka.discountPercent('1000', '750'), 25);
      expect(Taka.discountPercent('1000', '0'), 0);
      expect(Taka.discountPercent('1000', '1200'), 0);
    });
  });
}
