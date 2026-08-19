import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/phone_number_sql.dart';

void main() {
  group('PhoneNumberSql.matchKeyOf', () {
    test('ramène toutes les écritures d\'un même numéro à la même clé', () {
      const expected = '816939060';
      for (final raw in <String>[
        '816939060',
        '0816939060',
        '+243816939060',
        '00243816939060',
        '+243 81 693 90 60',
        '(0)81-693-9060',
      ]) {
        expect(PhoneNumberSql.matchKeyOf(raw), expected, reason: raw);
      }
    });

    test('compare un numéro court en entier', () {
      expect(PhoneNumberSql.matchKeyOf('12345'), '12345');
      expect(PhoneNumberSql.matchKeyOf(''), '');
    });

    test('distingue deux numéros réellement différents', () {
      expect(
        PhoneNumberSql.matchKeyOf('+243816939060'),
        isNot(PhoneNumberSql.matchKeyOf('+243816939061')),
      );
    });
  });

  group('PhoneNumberSql.matchKey', () {
    test('rend une expression SQL appliquée à la colonne', () {
      final sql = PhoneNumberSql.matchKey('phone_number');
      expect(sql, startsWith('SUBSTR('));
      expect(sql, contains('phone_number'));
      expect(sql, endsWith(', -9)'));
    });
  });
}
