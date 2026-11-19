import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_editor.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_printer.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/class_timetable_reader.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_cubit.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../../core/offline/offline_full_test_db.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(<String>{});
    registerFallbackValue(
      const ClassTimetableView(
        classroom: TimetableClassOption(
          classroomId: '',
          name: '',
          cycleCode: '',
          cycleName: '',
          levelCode: '',
          levelName: '',
        ),
        grid: null,
        slots: [],
        header: null,
        published: [],
        draft: [],
        programme: [],
        othersKnown: false,
      ),
    );
  });

  late Database db;
  setUp(() async => db = await openFullOfflineDb());
  tearDown(() => db.close());

  test('une classe inconnue dans l’adresse ne laisse pas un chargement sans '
      'fin : l’adresse se corrige', () async {
    final cubit = ClassTimetableCubit(
      ClassTimetableReader(db, SyncMetaDao(db), schoolId: () => 's'),
      schoolToday: () => DateTime.utc(2026, 10, 1),
    );
    await cubit.load();
    await cubit.selectClass('fermee');
    expect(cubit.state.status, ClassTimetableStatus.ready);
    expect(cubit.state.classroomId, isNull);
    expect(cubit.state.view, isNull);
    await cubit.close();
  });

  test('changer de classe garde la semaine choisie', () async {
    final cubit = ClassTimetableCubit(
      ClassTimetableReader(db, SyncMetaDao(db), schoolId: () => 's'),
      schoolToday: () => DateTime.utc(2026, 10, 1),
    );
    await cubit.load();
    await cubit.setWeek(DateTime.utc(2026, 10, 14));
    await cubit.selectClass('autre');
    expect(cubit.state.week, DateTime.utc(2026, 10, 12));
    await cubit.close();
  });

  test('une version dépassée : l’en-tête est re-tiré, puis la pièce repart '
      'une fois avec la version courante', () async {
    final reader = _Reader();
    final printer = _Printer();
    final coordinator = _Coordinator();
    const option = TimetableClassOption(
      classroomId: 'c7a',
      name: '7e A',
      cycleCode: 'SEC',
      cycleName: 'Sec',
      levelCode: 'L7',
      levelName: '7e',
    );
    ClassTimetableView viewAt(int version) => ClassTimetableView(
      classroom: option,
      grid: null,
      slots: const [],
      header: ClassTimetableHeader(
        id: 'h',
        classroomId: 'c7a',
        academicYearId: 'y',
        revision: 1,
        publishedVersion: version,
      ),
      published: const [],
      draft: const [],
      programme: const [],
      othersKnown: true,
    );
    var version = 3;
    when(() => reader.classOptions()).thenAnswer((_) async => [option]);
    when(() => reader.load(option)).thenAnswer((_) async => viewAt(version));
    when(() => coordinator.pullSubset(any())).thenAnswer((_) async {
      version = 4;
      return const PullRunReport();
    });
    final document = PrintableDocument(
      bytes: Uint8List.fromList(const [1]),
      fileName: 'ET.pdf',
    );
    when(() => printer.print(any())).thenAnswer(
      (i) async =>
          (i.positionalArguments.single as ClassTimetableView)
                  .header!
                  .publishedVersion ==
              3
          ? const Left(TimetableRefusalFailure('TIMETABLE_VERSION_CHANGED'))
          : Right(document),
    );
    final cubit = ClassTimetableCubit(
      reader,
      printer: printer,
      coordinator: coordinator,
      schoolToday: () => DateTime.utc(2026, 10, 1),
    );
    await cubit.load();
    await cubit.selectClass('c7a');
    final result = await cubit.printPublished();
    expect(result, Right<Failure, PrintableDocument>(document));
    verify(() => printer.print(any())).called(2);
    expect(cubit.state.busy, isFalse);
    await cubit.close();
  });
}

class _Reader extends Mock implements ClassTimetableReader {}

class _Printer extends Mock implements TimetablePrinter {}

class _Coordinator extends Mock implements PullCoordinator {}
