import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_with_members.dart';
import 'package:school_app_flutter/features/classes/domain/entities/level_distribution_overview.dart';
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

  ClassroomWithMembers bucket(String name, int capacity, int count) =>
      ClassroomWithMembers(
        classroom: Classroom(
          id: 'c-$name',
          schoolLevelGroupId: 'g',
          schoolLevelId: 'l',
          academicYearId: 'y',
          name: name,
          capacity: capacity,
          teacherId: null,
          teacherFirstName: null,
          teacherLastName: null,
          teacherMiddleName: null,
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
              i.isEven
                  ? ClassroomMemberGender.male
                  : ClassroomMemberGender.female,
            ),
        ],
      );

  final overview = LevelDistributionOverview(
    unassignedEnrollments: const [
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
    ],
    classrooms: [bucket('A', 40, 5), bucket('B', 40, 40), bucket('C', 40, 35)],
  );

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
        classrooms: <BootstrapClassroom>[],
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
          home: Scaffold(
            // Reproduit la vraie page : largeur bornée + hauteur NON bornée.
            body: Center(
              child: SizedBox(
                width: width,
                child: SingleChildScrollView(child: child),
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
        overviewStatus: ClassroomStatus.success,
        overviewErrorType: ClassroomErrorType.none,
        overview: overview,
        isReassigning: false,
        reassigningMemberId: '',
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
        members: [
          member(
            '1',
            'Nguyen-Van-Tran',
            'Jean-Baptiste',
            'Marie-Christine',
            ClassroomMemberGender.female,
          ),
          member(
            '2',
            'Nguyen-Van-Tran',
            'Jean-Baptiste',
            'Marie-Christine',
            ClassroomMemberGender.male,
          ),
        ],
        isReassigning: false,
        reassigningMemberId: '',
        onTransferTap: (_) {},
      ),
    );
  });
}

void _noop() {}
