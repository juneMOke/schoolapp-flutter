import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/attachments/attachment_availability.dart';
import 'package:school_app_flutter/core/attachments/attachment_ref.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/resource_sync_signals.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/attendance_justification.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/justification_enums.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/justification/attendance_justification_repository.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/justification/attendance_justification_use_cases.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/bloc/justification_queue_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/bloc/justification_queue_state.dart';

class _Repository extends Mock implements AttendanceJustificationRepository {}

class _Engine extends Mock implements SyncEngine {}

class _Availability extends Mock implements AttachmentAvailabilityTracker {}

void main() {
  const ref = AttachmentRef(
    name: 'c.pdf',
    mimeType: 'application/pdf',
    sizeBytes: 1,
    sha256: 'abc',
  );

  AttendanceJustification justification(
    String id, {
    JustificationStatus status = JustificationStatus.pending,
    JustificationDecision? local,
    bool elsewhere = false,
  }) => AttendanceJustification(
    id: id,
    studentId: 's',
    classroomId: 'c',
    academicYearId: 'y1',
    attendanceDate: '2026-10-14',
    reason: AbsenceReason.sickness,
    status: status,
    localDecision: local,
    decidedElsewhere: elsewhere,
    attachment: ref,
  );

  late _Repository repository;
  late _Availability availability;
  late StreamController<bool> radio;
  late int pulls;

  JustificationQueueCubit build() {
    final engine = _Engine();
    when(() => engine.addFlushCompleteListener(any())).thenReturn(() {});
    return JustificationQueueCubit(
      load: LoadAttendanceJustificationsUseCase(repository),
      decide: DecideAttendanceJustificationUseCase(repository),
      attachment: OpenJustificationAttachmentUseCase(repository),
      acknowledge: AcknowledgeJustificationNoticeUseCase(repository),
      signals: ResourceSyncSignals(
        bus: PullCompletionBus(),
        engine: engine,
        watched: const {'attendance_justifications'},
        pull: () async => pulls++,
      ),
      availability: availability,
    );
  }

  setUpAll(() {
    registerFallbackValue(justification('fallback'));
    registerFallbackValue(JustificationDecision.accept);
  });

  setUp(() {
    pulls = 0;
    repository = _Repository();
    availability = _Availability();
    radio = StreamController<bool>.broadcast();
    when(() => availability.watch(any())).thenAnswer((invocation) {
      final onChanged =
          invocation.positionalArguments.single as void Function(bool);
      final sub = radio.stream.listen(onChanged);
      return () => unawaited(sub.cancel());
    });
    when(
      () => availability.snapshot(any()),
    ).thenAnswer((_) async => const AttachmentAvailability(online: false));
    when(
      () => repository.acknowledgeDecidedElsewhere(any()),
    ).thenAnswer((_) async => const Right(unit));
  });

  tearDown(() => radio.close());

  test('l année ouvre la file et lance la descente du flux', () async {
    when(() => repository.list('y1')).thenAnswer(
      (_) async => Right([
        justification('a'),
        justification('b', local: JustificationDecision.accept),
        justification('c', status: JustificationStatus.rejected),
      ]),
    );
    final cubit = build();

    await cubit.setAcademicYear('y1');

    final state = cubit.state;
    expect(state.load, JustificationQueueLoad.ready);
    expect(pulls, 1);
    expect(state.visible.map((j) => j.id), ['a', 'b']);
    // Une décision en route n'attend plus l'école.
    expect(state.awaitingCount, 1);
    expect(state.attachments.canOpen(ref), isFalse);
    cubit.setFilter(JustificationQueueFilter.decided);
    expect(cubit.state.visible.map((j) => j.id), ['c']);
    await cubit.close();
  });

  test('la radio qui revient rend les pièces ouvrables', () async {
    when(
      () => repository.list('y1'),
    ).thenAnswer((_) async => Right([justification('a')]));
    final cubit = build();
    await cubit.setAcademicYear('y1');

    radio.add(true);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.attachments.canOpen(ref), isTrue);
    await cubit.close();
  });

  test('une pièce obtenue reste ouvrable hors ligne', () async {
    when(
      () => repository.list('y1'),
    ).thenAnswer((_) async => Right([justification('a')]));
    when(
      () => repository.attachment(any()),
    ).thenAnswer((_) async => Right(Uint8List(1)));
    final cubit = build();
    await cubit.setAcademicYear('y1');

    await cubit.attachment(justification('a'));

    expect(cubit.state.attachments.canOpen(ref), isTrue);
    await cubit.close();
  });

  test('une lecture en échec ne remplace pas une file déjà montrée', () async {
    when(
      () => repository.list('y1'),
    ).thenAnswer((_) async => Right([justification('a')]));
    final cubit = build();
    await cubit.setAcademicYear('y1');
    when(
      () => repository.list('y1'),
    ).thenAnswer((_) async => const Left(StorageFailure('x')));

    await cubit.refresh();

    expect(cubit.state.load, JustificationQueueLoad.ready);
    expect(cubit.state.all, hasLength(1));
    await cubit.close();
  });

  test(
    '« tranchée par un autre poste » : annoncée une fois, puis oubliée',
    () async {
      when(() => repository.list('y1')).thenAnswer(
        (_) async => Right([
          justification(
            'a',
            status: JustificationStatus.rejected,
            elsewhere: true,
          ),
        ]),
      );
      final cubit = build();
      await cubit.setAcademicYear('y1');
      expect(cubit.state.decidedElsewhere, hasLength(1));

      await cubit.acknowledgeDecidedElsewhere();

      expect(cubit.state.decidedElsewhere, isEmpty);
      verify(() => repository.acknowledgeDecidedElsewhere('a')).called(1);
      await cubit.close();
    },
  );

  test('décider relit la file et rend l issue', () async {
    when(
      () => repository.list('y1'),
    ).thenAnswer((_) async => Right([justification('a')]));
    when(
      () => repository.decide(any(), any(), note: any(named: 'note')),
    ).thenAnswer((_) async => const Left(ConflictFailure()));
    final cubit = build();
    await cubit.setAcademicYear('y1');

    final result = await cubit.decide(
      justification('a'),
      JustificationDecision.reject,
      note: 'Non',
    );

    expect(result, const Left<Failure, Unit>(ConflictFailure()));
    verify(() => repository.list('y1')).called(2);
    await cubit.close();
  });
}
