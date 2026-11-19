import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/copy_source.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/timetable_copy_plan.dart';

const _option = TimetableClassOption(
  classroomId: 'c7c',
  name: '7e C',
  cycleCode: 'SEC',
  cycleName: 'S',
  levelCode: 'L',
  levelName: 'L',
);

void main() {
  test(
    'la copie nomme toutes les cases de la grille, et reprend par branche',
    () {
      const slots = [
        TimeSlot(
          id: 's1',
          order: 1,
          startTime: '07:30:00',
          endTime: '08:20:00',
        ),
        TimeSlot(
          id: 's2',
          order: 2,
          startTime: '08:20:00',
          endTime: '09:10:00',
        ),
      ];
      final target = ClassTimetableView(
        classroom: _option,
        grid: null,
        slots: slots,
        header: null,
        published: const [],
        draft: const [],
        programme: const [
          TimetableCourse(
            coursId: 'fr7c',
            classroomId: 'c7c',
            branchId: 'FR',
            branchLabel: 'Français',
            teacherId: 't9',
          ),
        ],
        othersKnown: true,
      );
      final source = CopySource(
        classroom: _option,
        isDraft: false,
        branchByCours: const {'fr7a': 'FR', 'lat7a': 'LAT'},
        cells: const [
          ClassTimetableCell(
            id: 'a',
            classroomId: 'c7a',
            classroomLabel: '7e A',
            status: TimetableCellStatus.published,
            day: Weekday.mon,
            slotId: 's1',
            range: MinuteRange(450, 500),
            coursId: 'fr7a',
          ),
          ClassTimetableCell(
            id: 'b',
            classroomId: 'c7a',
            classroomLabel: '7e A',
            status: TimetableCellStatus.published,
            day: Weekday.mon,
            slotId: 's2',
            range: MinuteRange(500, 550),
            coursId: 'lat7a',
          ),
        ],
      );
      final plan = TimetableCopyPlan.of(target, source);
      expect(plan.changes, hasLength(12)); // 6 jours × 2 créneaux
      expect(plan.changes.first.course!.coursId, 'fr7c');
      expect(plan.changes[1].course, isNull);
      expect((plan.result.taken, plan.result.noEquivalent), (1, 1));
    },
  );
}
