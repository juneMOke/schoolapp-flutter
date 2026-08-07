import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/search/search_invitation_card.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_classroom_card.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_results_section.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_unassigned_members_section.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockClassroomBloc extends MockBloc<ClassroomEvent, ClassroomState>
    implements ClassroomBloc {}

class MockClassroomOfflineBloc
    extends MockBloc<ClassroomOfflineEvent, ClassroomOfflineState>
    implements ClassroomOfflineBloc {}

class _MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

void main() {
  late MockClassroomBloc classroomBloc;
  late MockClassroomOfflineBloc offlineBloc;
  late _MockSyncStatusCubit syncStatusCubit;

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
  );

  const splitLevel = ClassesOrganisationLevelOption(
    schoolLevelGroupId: 'cycle-1',
    schoolLevelGroupName: 'Primaire',
    schoolLevelId: 'level-1',
    schoolLevelName: '2eme annee',
    splitIntoClassrooms: true,
  );

  const unassignedEnrollments = <EnrollmentSummary>[
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
  ];

  const offlineClassroom = OfflineClassroom(
    id: 'class-1',
    academicYearId: 'year-1',
    schoolLevelGroupId: 'cycle-1',
    schoolLevelId: 'level-1',
    name: 'Classe A',
    capacity: 40,
    totalCount: 1,
    femaleCount: 1,
    maleCount: 0,
  );

  const offlineMembers = <ClassroomMember>[
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
  ];

  setUp(() {
    classroomBloc = MockClassroomBloc();
    when(() => classroomBloc.state).thenReturn(const ClassroomState());
    whenListen(
      classroomBloc,
      const Stream<ClassroomState>.empty(),
      initialState: const ClassroomState(),
    );
    offlineBloc = MockClassroomOfflineBloc();
    when(() => offlineBloc.state).thenReturn(const ClassroomOfflineState());
    whenListen(
      offlineBloc,
      const Stream<ClassroomOfflineState>.empty(),
      initialState: const ClassroomOfflineState(),
    );
    syncStatusCubit = _MockSyncStatusCubit();
    whenListen(
      syncStatusCubit,
      const Stream<SyncStatusState>.empty(),
      initialState: const SyncStatusState(status: SyncStatus.synced),
    );
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    required ClassesOrganisationCycleOption? selectedCycle,
    required ClassesOrganisationLevelOption? selectedLevel,
    ClassroomState? blocState,
    ClassroomOfflineState? offlineBlocState,
    bool settle = true,
  }) async {
    final state = blocState ?? const ClassroomState();
    when(() => classroomBloc.state).thenReturn(state);
    whenListen(
      classroomBloc,
      Stream<ClassroomState>.value(state),
      initialState: state,
    );

    final offlineStateValue = offlineBlocState ?? const ClassroomOfflineState();
    when(() => offlineBloc.state).thenReturn(offlineStateValue);
    whenListen(
      offlineBloc,
      Stream<ClassroomOfflineState>.value(offlineStateValue),
      initialState: offlineStateValue,
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
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ClassroomBloc>.value(value: classroomBloc),
            BlocProvider<ClassroomOfflineBloc>.value(value: offlineBloc),
            BlocProvider<SyncStatusCubit>.value(value: syncStatusCubit),
          ],
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

    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets(
    'affiche empty state global quand aucun cycle n est selectionne',
    (tester) async {
      await pumpSection(tester, selectedCycle: null, selectedLevel: null);

      expect(find.byType(SearchInvitationCard), findsOneWidget);
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

      expect(find.byType(SearchInvitationCard), findsOneWidget);
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
      // Non-affectés calculés 100% offline (remplace l'aperçu online) : la
      // carte lit désormais `levelUnassignedStatus`/`levelUnassignedEnrollments`.
      offlineBlocState: const ClassroomOfflineState(
        levelUnassignedStatus: ClassroomStatus.success,
        levelUnassignedEnrollments: unassignedEnrollments,
      ),
    );

    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsWidgets);
    expect(find.text('Niveau pas encore réparti'), findsOneWidget);
    // Un seul élève non affecté dans `unassignedEnrollments` (fille) → effectif 1, F · 1.
    expect(find.text('F · 1'), findsOneWidget);
    expect(find.text('G · 0'), findsOneWidget);
  });

  testWidgets(
    'affiche la zone a affecter quand overview contient des non affectes',
    (tester) async {
      await pumpSection(
        tester,
        selectedCycle: cycle,
        selectedLevel: splitLevel,
        offlineBlocState: const ClassroomOfflineState(
          levelClassroomsStatus: ClassroomStatus.success,
          levelClassrooms: <OfflineClassroom>[offlineClassroom],
          levelRosters: <String, List<ClassroomMember>>{
            'class-1': offlineMembers,
          },
          levelUnassignedStatus: ClassroomStatus.success,
          levelUnassignedEnrollments: unassignedEnrollments,
        ),
      );

      expect(
        find.byType(ClassesOrganisationUnassignedMembersSection),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'le spinner d\'affectation est piloté par ClassroomOfflineBloc (bloc '
    'qui reçoit réellement MemberAssignRequested), pas ClassroomBloc online',
    (tester) async {
      await pumpSection(
        tester,
        selectedCycle: cycle,
        selectedLevel: splitLevel,
        offlineBlocState: const ClassroomOfflineState(
          levelClassroomsStatus: ClassroomStatus.success,
          levelClassrooms: <OfflineClassroom>[offlineClassroom],
          levelRosters: <String, List<ClassroomMember>>{
            'class-1': offlineMembers,
          },
          levelUnassignedStatus: ClassroomStatus.success,
          levelUnassignedEnrollments: unassignedEnrollments,
          // État réellement atteignable : l'affectation cible un DOSSIER
          // d'inscription (zone ambre), jamais un membre de classe — d'où
          // l'identité `enr-1` et non un `classroomMemberId`.
          assignStatus: ClassroomStatus.loading,
          assigningEnrollmentId: 'enr-1',
        ),
        // pumpAndSettle ne termine jamais tant qu'un CircularProgressIndicator
        // (animation indéterminée perpétuelle) est monté.
        settle: false,
      );

      // Un seul spinner : la tuile du non-réparti visé. Les tuiles de la zone
      // classes se figent (opacité) mais n'affichent jamais d'attente — une
      // affectation ne les concerne pas.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ClassesOrganisationUnassignedMembersSection),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'affiche les classes depuis le cache local même si l aperçu online est en échec',
    (tester) async {
      await pumpSection(
        tester,
        selectedCycle: cycle,
        selectedLevel: splitLevel,
        blocState: const ClassroomState(
          distributionOverviewStatus: ClassroomStatus.failure,
          distributionOverviewErrorType: ClassroomErrorType.network,
        ),
        offlineBlocState: const ClassroomOfflineState(
          levelClassroomsStatus: ClassroomStatus.success,
          levelClassrooms: <OfflineClassroom>[offlineClassroom],
          levelRosters: <String, List<ClassroomMember>>{
            'class-1': offlineMembers,
          },
        ),
      );

      expect(find.byType(ClassesOrganisationClassroomCard), findsOneWidget);
    },
  );
}
