import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_state.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_teachers_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/pages/journal_coordinator_page.dart';
import 'package:school_app_flutter/features/class_journal/presentation/pages/journal_direction_page.dart';
import 'package:school_app_flutter/features/class_journal/presentation/pages/journal_page.dart';

import '../../../course_programme/presentation/programme_test_host.dart';

class _MockYear
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _MockDay extends MockCubit<JournalDayState> implements JournalDayCubit {}

class _MockTeachers extends MockCubit<JournalTeachersState>
    implements JournalTeachersCubit {}

void main() {
  final getIt = GetIt.instance;
  late _MockTeachers teachers;

  setUp(() {
    final day = _MockDay();
    final today = DateTime(2026, 10, 14);
    when(() => day.state).thenReturn(JournalDayIdle(date: today, today: today));
    teachers = _MockTeachers();
    when(() => teachers.state).thenReturn(const JournalTeachersState());
    when(() => teachers.load()).thenAnswer((_) async {});
    getIt
      ..registerFactory<JournalDayCubit>(() => day)
      ..registerFactory<JournalTeachersCubit>(() => teachers);
  });
  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester, List<String> permissions) async {
    final year = _MockYear();
    when(() => year.state).thenReturn(
      const AcademicYearContextState(
        status: AcademicYearContextLoadStatus.loading,
      ),
    );
    await tester.pumpWidget(
      programmeHost(
        BlocProvider<AcademicYearContextBloc>.value(
          value: year,
          child: const JournalCoordinatorPage(),
        ),
        permissions: permissions,
      ),
    );
    await tester.pump();
  }

  testWidgets('le professeur : son journal, en saisie', (tester) async {
    await pump(tester, kProgrammeTeacher);

    final page = tester.widget<JournalPage>(find.byType(JournalPage));
    expect(page.onOpen, isNotNull);
  });

  testWidgets('la direction : le choix d\'un professeur, en ligne', (
    tester,
  ) async {
    // Gabarit FULL_SCHOOL_ACCESS : la direction écrit AUSSI le programme.
    await pump(tester, const [
      'academics.course.read',
      'academics.programme.write',
      'teacher.read',
    ]);

    expect(find.byType(JournalDirectionPage), findsOneWidget);
    verify(() => teachers.load()).called(1);
  });

  testWidgets('sans écriture ni lecture des professeurs : lecture seule', (
    tester,
  ) async {
    await pump(tester, kProgrammeReader);

    final page = tester.widget<JournalPage>(find.byType(JournalPage));
    expect(page.onOpen, isNull);
  });
}
