import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/formatters/local_date_time_format.dart';

void main() {
  group('formatSchoolDateTime', () {
    test('lit l\'instant à Kinshasa, pas au fuseau du poste', () {
      expect(
        formatSchoolDateTime(DateTime.utc(2026, 8, 30, 9, 42)),
        '30/08/2026 10:42',
      );
    });

    test('23 h 30 UTC tombe le lendemain à l\'école', () {
      expect(
        formatSchoolDateTime(DateTime.utc(2026, 8, 29, 23, 30)),
        '30/08/2026 00:30',
      );
    });
  });
}
