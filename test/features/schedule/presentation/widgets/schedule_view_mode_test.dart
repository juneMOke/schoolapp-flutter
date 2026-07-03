import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_view_mode.dart';

void main() {
  group('defaultScheduleViewMode', () {
    test('téléphone / petit écran (< 600) → mode Jour', () {
      expect(defaultScheduleViewMode(320), ScheduleViewMode.day);
      expect(defaultScheduleViewMode(480), ScheduleViewMode.day);
      expect(defaultScheduleViewMode(599.9), ScheduleViewMode.day);
    });

    test('écran large (>= 600) → mode Semaine', () {
      expect(defaultScheduleViewMode(600), ScheduleViewMode.week);
      expect(defaultScheduleViewMode(1024), ScheduleViewMode.week);
    });
  });
}
