import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/presence/domain/presence_justification.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_closure.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_month.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/register/class_presence_use_cases.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_commands.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_notice.dart';

import 'class_presence_fixtures.dart';

class _Save extends Mock implements SaveClassPresenceMarksUseCase {}

class _Validate extends Mock implements ValidateClassPresenceDayUseCase {}

class _Reopen extends Mock implements ReopenClassPresenceDayUseCase {}

class _Retry extends Mock implements RetryClassPresenceDayUseCase {}

class _Close extends Mock implements CloseClassPresenceMonthUseCase {}

void main() {
  late _Save save;
  late _Validate validate;
  late _Reopen reopen;
  late _Close close;
  late ClassPresenceCommands commands;

  setUpAll(() {
    registerFallbackValue(const (classroomId: '', academicYearId: '', day: ''));
    registerFallbackValue(<String, PresenceMark<AbsenceReason>>{});
    registerFallbackValue(<ClassPresenceLine>[]);
    registerFallbackValue(const (
      classroomId: '',
      academicYearId: '',
      month: '',
    ));
  });

  setUp(() {
    save = _Save();
    validate = _Validate();
    reopen = _Reopen();
    close = _Close();
    when(() => close(any())).thenAnswer((_) async => const Right(unit));
    when(() => save(any(), any())).thenAnswer((_) async => const Right(unit));
    when(
      () => validate(any(), any()),
    ).thenAnswer((_) async => const Right(unit));
    when(() => reopen(any())).thenAnswer((_) async => const Right(unit));
    commands = ClassPresenceCommands(
      save: save,
      validate: validate,
      reopen: reopen,
      retry: _Retry(),
      close: close,
      // 07:20 : avant la tolérance, « présent » prend l'heure courante.
      now: () => DateTime(2026, 10, 1, 7, 20),
    );
  });

  test('une touche sur un appel à faire va au brouillon', () async {
    final day = presenceDay();
    await commands.cycle(day, day.lines[2]);

    final marks =
        verify(() => save(any(), captureAny())).captured.single
            as Map<String, PresenceMark<AbsenceReason>>;
    expect(marks['s3']!.status, PresenceStatus.present);
    expect(marks['s3']!.arrival?.wire, '07:20');
    verifyNever(() => validate(any(), any()));
  });

  test('un appel validé refuse les touches', () async {
    final day = presenceDay(validated: true);
    final notice = await commands.cycle(day, day.lines.first);

    expect(notice?.kind, ClassPresenceNoticeKind.dayFrozen);
    verifyNever(() => save(any(), any()));
  });

  test('un mois clôturé refuse tout, justification comprise', () async {
    final day = presenceDay(validated: true, monthClosed: true);
    final notice = await commands.justify(
      day,
      day.lines[1],
      const PresenceJustification(reason: AbsenceReason.sickness),
    );

    expect(notice?.kind, ClassPresenceNoticeKind.monthFrozen);
    verifyNever(() => validate(any(), any()));
  });

  test(
    'justifier un appel validé le renvoie aussitôt, sans le rouvrir',
    () async {
      final day = presenceDay(validated: true);
      final notice = await commands.justify(
        day,
        day.lines[1],
        const PresenceJustification(reason: AbsenceReason.sickness),
      );

      expect(notice?.kind, ClassPresenceNoticeKind.justified);
      final lines =
          verify(() => validate(any(), captureAny())).captured.single
              as List<ClassPresenceLine>;
      expect(lines, hasLength(3));
      expect(lines[1].mark.justification?.reason, AbsenceReason.sickness);
      expect(lines[0], day.lines[0]);
      verifyNever(() => reopen(any()));
      verifyNever(() => save(any(), any()));
    },
  );

  test('valider marque présents à l heure de début les non pointés', () async {
    final day = presenceDay();
    final notice = await commands.validate(day, classroomName: '6e A');

    expect(notice?.kind, ClassPresenceNoticeKind.validated);
    expect(notice?.name, '6e A');
    final lines =
        verify(() => validate(any(), captureAny())).captured.single
            as List<ClassPresenceLine>;
    final esther = lines.firstWhere((l) => l.student.id == 's3');
    expect(esther.status, PresenceStatus.present);
    expect(esther.mark.arrival?.wire, '07:30');
    expect(lines.every((l) => l.status.isMarked), isTrue);
  });

  test(
    'un motif inconnu de la tablette bloque validation et réouverture',
    () async {
      final day = presenceDay(
        lines: [
          ClassPresenceLine.read(
            student: grace,
            mark: const PresenceMark(status: PresenceStatus.absent),
            reason: AbsenceReason.unsupported,
            note: null,
          ),
        ],
      );
      expect(
        (await commands.validate(day, classroomName: '6e A'))?.kind,
        ClassPresenceNoticeKind.unsupportedReason,
      );
      expect(
        (await commands.reopen(day))?.kind,
        ClassPresenceNoticeKind.unsupportedReason,
      );
      verifyNever(() => validate(any(), any()));
      verifyNever(() => reopen(any()));
    },
  );

  test('clôturer le mois : le geste part, l annonce nomme le mois', () async {
    const month = ClassPresenceMonth(
      classroomId: 'c1',
      academicYearId: 'y1',
      month: '2026-09',
      students: [],
      calledDays: {},
      incidents: {},
    );
    final notice = await commands.closeMonth(month, classroomName: '6e A');

    expect(notice?.kind, ClassPresenceNoticeKind.monthClosed);
    expect(notice?.month, '2026-09');
    verify(() => close(any())).called(1);

    final already = await commands.closeMonth(
      const ClassPresenceMonth(
        classroomId: 'c1',
        academicYearId: 'y1',
        month: '2026-09',
        students: [],
        calledDays: {},
        incidents: {},
        closure: ClassPresenceClosure(),
      ),
      classroomName: '6e A',
    );
    expect(already?.kind, ClassPresenceNoticeKind.monthFrozen);
    verifyNoMoreInteractions(close);
  });
}
