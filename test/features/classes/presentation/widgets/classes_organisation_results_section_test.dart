import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_with_members.dart';
import 'package:school_app_flutter/features/classes/domain/entities/level_distribution_overview.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_results_section.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_unassigned_members_section.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockClassroomBloc extends MockBloc<ClassroomEvent, ClassroomState>
    implements ClassroomBloc {}

void main() {
  late MockClassroomBloc classroomBloc;

  const cycle = ClassesOrganisationCycleOption(
    id: 'cycle-1',
    label: 'Primaire',
    levels: <ClassesOrganisationLevelOption>[],
  );

  const nonSplitLevel = ClassesOrganisationLevelOption(
    schoolLevelGroupId: 'cycle-1',
    schoolLevelGroupName: 'Primaire',
    schoolLevelId: 'level-1',
    schoolLevelName: '2eme annee',
    splitIntoClassrooms: false,
    classrooms: <BootstrapClassroom>[
      BootstrapClassroom(
        id: 'class-1',
        version: 1,
        schoolLevelId: 'level-1',
        name: 'Classe A',
        capacity: 40,
        totalCount: 0,
        femaleCount: 0,
        maleCount: 0,
      ),
    ],
  );

  const splitLevel = ClassesOrganisationLevelOption(
    schoolLevelGroupId: 'cycle-1',
    schoolLevelGroupName: 'Primaire',
    schoolLevelId: 'level-1',
    schoolLevelName: '2eme annee',
    splitIntoClassrooms: true,
    classrooms: <BootstrapClassroom>[
      BootstrapClassroom(
        id: 'class-1',
        version: 1,
        schoolLevelId: 'level-1',
        name: 'Classe A',
        capacity: 40,
        totalCount: 1,
        femaleCount: 1,
        maleCount: 0,
      ),
    ],
  );

  const overview = LevelDistributionOverview(
    unassignedEnrollments: <EnrollmentSummary>[
      EnrollmentSummary(
        enrollmentId: 'enr-1',
        enrollmentCode: 'ENR-1',
        status: 'COMPLETED',
        student: StudentSummary(
          id: 'student-1',
          firstName: 'Jane',
          lastName: 'Doe',
          surname: 'K',
          dateOfBirth: '2012-01-01',
          gender: Gender.female,
        ),
      ),
    ],
    classrooms: <ClassroomWithMembers>[
      ClassroomWithMembers(
        classroom: Classroom(
          id: 'class-1',
          schoolLevelGroupId: 'cycle-1',
          schoolLevelId: 'level-1',
          academicYearId: 'year-1',
          name: 'Classe A',
          capacity: 40,
          teacherId: null,
          teacherFirstName: null,
          teacherLastName: null,
          teacherMiddleName: null,
          totalCount: 1,
          femaleCount: 1,
          maleCount: 0,
        ),
        members: <ClassroomMember>[
          ClassroomMember(
            id: 'member-1',
            studentId: 'student-2',
            classroomId: 'class-1',
            academicYearId: 'year-1',
            studentFirstName: 'Anna',
            studentLastName: 'Smith',
            studentMiddleName: 'L',
            studentGender: ClassroomMemberGender.female,
          ),
        ],
      ),
    ],
  );

  setUp(() {
    classroomBloc = MockClassroomBloc();
    when(() => classroomBloc.state).thenReturn(const ClassroomState());
    whenListen(
      classroomBloc,
      const Stream<ClassroomState>.empty(),
      initialState: const ClassroomState(),
    );
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    required ClassesOrganisationCycleOption? selectedCycle,
    required ClassesOrganisationLevelOption? selectedLevel,
    ClassroomState? blocState,
  }) async {
    final state = blocState ?? const ClassroomState();
    when(() => classroomBloc.state).thenReturn(state);
    whenListen(
      classroomBloc,
      Stream<ClassroomState>.value(state),
      initialState: state,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<ClassroomBloc>.value(
          value: classroomBloc,
          child: Scaffold(
            body: SingleChildScrollView(
              child: ClassesOrganisationResultsSection(
                selectedCycle: selectedCycle,
                selectedLevel: selectedLevel,
                isDistributing: false,
                onDistributionRequested: () {},
                onTransferTap: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets(
    'affiche empty state global quand aucun cycle n est selectionne',
    (tester) async {
      await pumpSection(tester, selectedCycle: null, selectedLevel: null);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data ?? '').toLowerCase().contains('cycle') &&
              (widget.data ?? '').toLowerCase().contains('niveau'),
        ),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'affiche empty state niveau quand cycle selectionne sans niveau',
    (tester) async {
      await pumpSection(tester, selectedCycle: cycle, selectedLevel: null);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data ?? '').toLowerCase().contains('niveau'),
        ),
        findsWidgets,
      );
    },
  );

  testWidgets('affiche la carte non reparti quand niveau split=false', (
    tester,
  ) async {
    await pumpSection(
      tester,
      selectedCycle: cycle,
      selectedLevel: nonSplitLevel,
      blocState: const ClassroomState(),
    );

    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsWidgets);
  });

  testWidgets(
    'affiche la zone a affecter quand overview contient des non affectes',
    (tester) async {
      await pumpSection(
        tester,
        selectedCycle: cycle,
        selectedLevel: splitLevel,
        blocState: const ClassroomState(
          distributionOverviewStatus: ClassroomStatus.success,
          distributionOverview: overview,
        ),
      );

      expect(
        find.byType(ClassesOrganisationUnassignedMembersSection),
        findsOneWidget,
      );
    },
  );
}
