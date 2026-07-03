import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

void main() {
  group('WeekdayX.wire', () {
    test('sérialise en majuscules MON..SAT', () {
      expect(Weekday.mon.wire, 'MON');
      expect(Weekday.tue.wire, 'TUE');
      expect(Weekday.wed.wire, 'WED');
      expect(Weekday.thu.wire, 'THU');
      expect(Weekday.fri.wire, 'FRI');
      expect(Weekday.sat.wire, 'SAT');
    });
  });

  group('WeekdayX.fromWire', () {
    test('round-trip pour toutes les valeurs', () {
      for (final day in Weekday.values) {
        expect(WeekdayX.fromWire(day.wire), day);
      }
    });

    test('insensible à la casse', () {
      expect(WeekdayX.fromWire('mon'), Weekday.mon);
      expect(WeekdayX.fromWire('Sat'), Weekday.sat);
    });

    test('valeur inconnue -> repli sur mon', () {
      expect(WeekdayX.fromWire('SUN'), Weekday.mon);
      expect(WeekdayX.fromWire('whatever'), Weekday.mon);
    });

    test('null ou vide -> repli sur mon', () {
      expect(WeekdayX.fromWire(null), Weekday.mon);
      expect(WeekdayX.fromWire(''), Weekday.mon);
    });
  });
}
