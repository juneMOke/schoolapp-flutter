import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';

void main() {
  group('isDay', () {
    test('un jour civil réel', () {
      expect(SchoolDayCalendar.isDay('2026-09-29'), isTrue);
      expect(SchoolDayCalendar.isDay('2028-02-29'), isTrue);
    });

    test('ni un jour impossible, ni un format tronqué ou lâche', () {
      expect(SchoolDayCalendar.isDay('2026-02-30'), isFalse);
      expect(SchoolDayCalendar.isDay('2026-13-01'), isFalse);
      expect(SchoolDayCalendar.isDay('2026-09'), isFalse);
      expect(SchoolDayCalendar.isDay('2026-9-29'), isFalse);
      expect(SchoolDayCalendar.isDay('29/09/2026'), isFalse);
      expect(SchoolDayCalendar.isDay(''), isFalse);
    });
  });
}
