import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_pending_distribution_card.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_search_form.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_split_results.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_unassigned_members_section.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

/// Largeurs représentatives : téléphone très étroit → desktop.
const _widths = <double>[320, 360, 700, 1100];

void main() {
  // ---- Fixtures -------------------------------------------------------------

  ClassroomMember member(
    String id,
    String last,
    String mid,
    String first,
    ClassroomMemberGender g,
  ) => ClassroomMember(
    id: id,
    studentId: 's-$id',
    classroomId: 'c',
    academicYearId: 'y',
    studentFirstName: first,
    studentLastName: last,
    studentMiddleName: mid,
    studentGender: g,
  );

  ({OfflineClassroom classroom, List<ClassroomMember> members}) bucket(
    String name,
    int capacity,
    int count,
  ) => (
    classroom: OfflineClassroom(
      id: 'c-$name',
      academicYearId: 'y',
      schoolLevelGroupId: 'g',
      schoolLevelId: 'l',
      name: name,
      capacity: capacity,
      totalCount: count,
      femaleCount: count ~/ 2,
      maleCount: count - count ~/ 2,
    ),
    members: [
      for (var i = 0; i < count; i++)
        member(
          '$name-$i',
          'Nguyen-Van-Tran',
          'Jean-Baptiste',
          'Marie-Christine',
          i.isEven ? ClassroomMemberGender.male : ClassroomMemberGender.female,
        ),
    ],
  );

  final buckets = [
    bucket('A', 40, 5),
    bucket('B', 40, 40),
    bucket('C', 40, 35),
  ];
  final overviewClassrooms = [for (final b in buckets) b.classroom];
  final overviewComposedRosters = {
    for (final b in buckets) b.classroom.id: b.members,
  };
  // Noms volontairement longs : la section non-répartie doit tenir à 320 px.
  EnrollmentSummary unassigned(String id, Gender gender) => EnrollmentSummary(
    enrollmentId: 'enr-$id',
    enrollmentCode: 'ENR-$id',
    status: 'COMPLETED',
    student: StudentSummary(
      id: 'stu-$id',
      firstName: 'Marie-Christine',
      lastName: 'Nguyen-Van-Tran',
      surname: 'Jean-Baptiste',
      dateOfBirth: '2014-01-01',
      gender: gender,
    ),
  );

  const overviewUnassignedEnrollments = [
    EnrollmentSummary(
      enrollmentId: 'enr-1',
      enrollmentCode: 'ENR-1',
      status: 'COMPLETED',
      student: StudentSummary(
        id: 'stu-1',
        firstName: 'Marie-Christine',
        lastName: 'Nguyen-Van-Tran',
        surname: 'Jean-Baptiste',
        dateOfBirth: '2014-01-01',
        gender: Gender.female,
      ),
    ),
  ];

  const cycle = ClassesOrganisationCycleOption(
    id: 'cycle-1',
    label: 'Secondaire',
    levels: [
      ClassesOrganisationLevelOption(
        schoolLevelGroupId: 'cycle-1',
        schoolLevelGroupName: 'Secondaire',
        schoolLevelId: 'level-1',
        schoolLevelName: '1H',
        splitIntoClassrooms: true,
      ),
    ],
  );

  // ---- Harnais --------------------------------------------------------------

  Future<void> pumpAtWidths(
    WidgetTester tester,
    Widget child, {
    bool settle = true,
  }) async {
    for (final width in _widths) {
      final syncStatusCubit = _MockSyncStatusCubit();
      whenListen(
        syncStatusCubit,
        const Stream<SyncStatusState>.empty(),
        initialState: const SyncStatusState(status: SyncStatus.synced),
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
          home: BlocProvider<SyncStatusCubit>.value(
            value: syncStatusCubit,
            // Reproduit la vraie page : largeur bornée + hauteur NON bornée.
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: SingleChildScrollView(child: child),
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
      expect(
        tester.takeException(),
        isNull,
        reason: 'Débordement/contrainte à ${width}px',
      );
    }
  }

  // ---- Tests ----------------------------------------------------------------

  testWidgets('carte d\'en-tête (eyebrow + cascade) sans débordement', (
    tester,
  ) async {
    await pumpAtWidths(
      tester,
      ClassesOrganisationSearchForm(
        schoolYear: '2026-2027',
        cycles: const [cycle],
        selectedCycleId: 'cycle-1',
        selectedLevelId: null,
        onCycleChanged: (_) {},
        onLevelChanged: (_) {},
      ),
    );
  });

  testWidgets('vue répartie (grille) sans débordement, noms longs', (
    tester,
  ) async {
    await pumpAtWidths(
      tester,
      ClassesOrganisationSplitResults(
        classroomsStatus: ClassroomStatus.success,
        classroomsErrorType: ClassroomErrorType.none,
        classrooms: overviewClassrooms,
        composedRosters: overviewComposedRosters,
        unassignedEnrollments: overviewUnassignedEnrollments,
        isAssigning: false,
        assigningEnrollmentId: '',
        errorMessage: null,
        onTransferTap: (_) {},
        onRetry: () {},
      ),
    );
  });

  testWidgets('carte « niveau non réparti » sans débordement', (tester) async {
    await pumpAtWidths(
      tester,
      const ClassesOrganisationPendingDistributionCard(
        isDistributing: false,
        overviewStatus: ClassroomStatus.success,
        levelName: '1H',
        studentsToDistribute: 42,
        maleCount: 22,
        femaleCount: 20,
        onDistributionRequested: _noop,
      ),
    );
  });

  testWidgets('section « non répartis » sans débordement', (tester) async {
    await pumpAtWidths(
      tester,
      ClassesOrganisationUnassignedMembersSection(
        count: 3,
        enrollments: [
          unassigned('1', Gender.female),
          unassigned('2', Gender.male),
        ],
        isReassigning: false,
        assigningEnrollmentId: '',
        onTransferTap: (_) {},
      ),
    );
  });
}

void _noop() {}
