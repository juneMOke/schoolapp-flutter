import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/helpers/number_formatter_helper.dart';

void main() {
  group('NumberFormatterHelper', () {
    test('formatYAxisLabel - values < 1000', () {
      expect(NumberFormatterHelper.formatYAxisLabel(0), '0');
      expect(NumberFormatterHelper.formatYAxisLabel(500), '500');
      expect(NumberFormatterHelper.formatYAxisLabel(999), '999');
    });

    test('formatYAxisLabel - values in thousands', () {
      expect(NumberFormatterHelper.formatYAxisLabel(1000), '1K');
      expect(NumberFormatterHelper.formatYAxisLabel(1500), '1.5K');
      expect(NumberFormatterHelper.formatYAxisLabel(5000), '5K');
      expect(NumberFormatterHelper.formatYAxisLabel(9999), '10K');
      expect(NumberFormatterHelper.formatYAxisLabel(10000), '10K');
      expect(NumberFormatterHelper.formatYAxisLabel(100000), '100K');
      expect(NumberFormatterHelper.formatYAxisLabel(999999), '1000K');
    });

    test('formatYAxisLabel - values in millions', () {
      expect(NumberFormatterHelper.formatYAxisLabel(1000000), '1M');
      expect(NumberFormatterHelper.formatYAxisLabel(1500000), '1.5M');
      expect(NumberFormatterHelper.formatYAxisLabel(5000000), '5M');
      expect(NumberFormatterHelper.formatYAxisLabel(10000000), '10M');
      expect(NumberFormatterHelper.formatYAxisLabel(100000000), '100M');
    });

    test('formatYAxisLabel - negative values', () {
      expect(NumberFormatterHelper.formatYAxisLabel(-500), '-500');
      expect(NumberFormatterHelper.formatYAxisLabel(-1500), '-1.5K');
      expect(NumberFormatterHelper.formatYAxisLabel(-1000000), '-1M');
    });

    test('formatYAxisLabel - decimal removal for whole numbers', () {
      // 10.0K should display as "10K", not "10.0K"
      expect(NumberFormatterHelper.formatYAxisLabel(10000), '10K');
      expect(NumberFormatterHelper.formatYAxisLabel(1000000), '1M');
    });
  });
}
