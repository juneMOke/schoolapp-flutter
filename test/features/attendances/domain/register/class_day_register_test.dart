import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/presence_justification.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_day.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_student.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_day_register.dart';

ClassPresenceStudent student(String id, String last, String first) =>
    ClassPresenceStudent(
      id: id,
      firstName: first,
      lastName: last,
      gender: StudentGender.female,
      number: 0,
    );

ClassPresenceLine line(
  ClassPresenceStudent s,
  PresenceStatus status, {
  AbsenceReason? reason,
  RecordSyncState sync = RecordSyncState.synced,
}) => ClassPresenceLine(
  student: s,
  mark: PresenceMark(
    status: status,
    justification: reason == null
        ? null
        : PresenceJustification(reason: reason),
  ),
  sync: sync,
);

ClassPresenceDay day(List<ClassPresenceLine> lines, {bool session = false}) =>
    ClassPresenceDay(
      classroomId: 'c1',
      academicYearId: 'y1',
      day: '2026-09-29',
      lines: lines,
      hasSession: session,
      reopened: false,
      schedule: PresenceSchedule.defaults,
    );

void main() {
  final grace = student('s1', 'Mbuyi', 'Grâce');
  final jean = student('s2', 'Ilunga', 'Jean');
  final esther = student('s3', 'Zola', 'Esther');

  group('ClassPresenceLine', () {
    test('un verdict d avant la v2 n est pas une justification', () {
      final read = ClassPresenceLine.read(
        student: grace,
        mark: const PresenceMark(status: PresenceStatus.absent),
        reason: AbsenceReason.unknown,
        note: 'à vérifier',
      );
      expect(read.mark.justification, isNull);
      expect(read.mark.needsJustification, isTrue);
      expect(read.wireReason, (AbsenceReason.unknown, 'à vérifier'));
    });

    test('un vrai motif justifie', () {
      final read = ClassPresenceLine.read(
        student: grace,
        mark: const PresenceMark(status: PresenceStatus.late),
        reason: AbsenceReason.transport,
        note: null,
      );
      expect(read.mark.justification?.reason, AbsenceReason.transport);
    });

    test('poser une justification abandonne le verdict gardé à part', () {
      final read = ClassPresenceLine.read(
        student: grace,
        mark: const PresenceMark(status: PresenceStatus.absent),
        reason: AbsenceReason.unjustified,
        note: null,
      );
      final justified = read.withMark(
        const PresenceMark(
          status: PresenceStatus.absent,
          justification: PresenceJustification(reason: AbsenceReason.sickness),
        ),
      );
      expect(justified.keptReason, isNull);
      expect(justified.wireReason.$1, AbsenceReason.sickness);
    });

    test('un motif inconnu de la tablette bloque le renvoi', () {
      final read = ClassPresenceLine.read(
        student: grace,
        mark: const PresenceMark(status: PresenceStatus.absent),
        reason: AbsenceReason.unsupported,
        note: null,
      );
      expect(read.blocksResend, isTrue);
    });
  });

  group('ClassDayRegister', () {
    final lines = [
      line(grace, PresenceStatus.late, sync: RecordSyncState.pending),
      line(jean, PresenceStatus.absent, reason: AbsenceReason.sickness),
      line(esther, PresenceStatus.none),
    ];

    test('compte, à pointer, à justifier, sur la tablette', () {
      final register = ClassDayRegister.build(day(lines), ClassDayQuery.none);
      expect(register.count(PresenceStatus.late), 1);
      expect(register.marked, 2);
      expect(register.unmarked.single.student, esther);
      expect(register.toJustify, 1);
      expect(register.pending, 1);
      expect(register.frozen, isFalse);
    });

    test('la recherche ignore accents et casse, et combine le statut', () {
      final byText = ClassDayRegister.build(
        day(lines),
        const ClassDayQuery(text: 'grace mbu'),
      );
      expect(byText.rows.single.student, grace);

      final byStatus = ClassDayRegister.build(
        day(lines),
        const ClassDayQuery(status: PresenceStatus.none, text: 'grace'),
      );
      expect(byStatus.isFilteredEmpty, isTrue);
    });

    test('un appel validé fige le registre', () {
      final register = ClassDayRegister.build(
        day(lines, session: true),
        ClassDayQuery.none,
      );
      expect(register.frozen, isTrue);
    });
  });
}
