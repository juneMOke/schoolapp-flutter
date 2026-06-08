import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_with_members.dart';
import 'package:school_app_flutter/features/classes/domain/entities/level_distribution_overview.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_split_results.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  ClassroomWithMembers bucket(String name, int male, int female) {
    final members = <ClassroomMember>[
      for (var i = 0; i < male; i++)
        ClassroomMember(
          id: '$name-m$i',
          studentId: 's-$name-m$i',
          classroomId: 'c-$name',
          academicYearId: 'y',
          studentFirstName: 'F$i',
          studentLastName: 'L$i',
          studentMiddleName: null,
          studentGender: ClassroomMemberGender.male,
        ),
      for (var i = 0; i < female; i++)
        ClassroomMember(
          id: '$name-f$i',
          studentId: 's-$name-f$i',
          classroomId: 'c-$name',
          academicYearId: 'y',
          studentFirstName: 'G$i',
          studentLastName: 'H$i',
          studentMiddleName: null,
          studentGender: ClassroomMemberGender.female,
        ),
    ];
    return ClassroomWithMembers(
      classroom: Classroom(
        id: 'c-$name',
        schoolLevelGroupId: 'g',
        schoolLevelId: 'l',
        academicYearId: 'y',
        name: name,
        capacity: 40,
        teacherId: null,
        teacherFirstName: null,
        teacherLastName: null,
        teacherMiddleName: null,
        totalCount: members.length,
        femaleCount: female,
        maleCount: male,
      ),
      members: members,
    );
  }

  Future<void> pumpView(WidgetTester tester) async {
    final overview = LevelDistributionOverview(
      unassignedEnrollments: const <EnrollmentSummary>[],
      classrooms: [bucket('A', 1, 1), bucket('B', 1, 0)],
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
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClassesOrganisationSplitResults(
              overviewStatus: ClassroomStatus.success,
              overviewErrorType: ClassroomErrorType.none,
              overview: overview,
              isReassigning: false,
              reassigningMemberId: '',
              errorMessage: null,
              onTransferTap: (_) {},
              onRetry: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('bandeau de synthèse : 4 KPI + basculeur Grille/Liste', (
    tester,
  ) async {
    await pumpView(tester);

    expect(find.text('Effectif'), findsOneWidget);
    expect(find.text('Classes'), findsOneWidget);
    expect(find.text('Garçons'), findsOneWidget);
    expect(find.text('Filles'), findsOneWidget);
    expect(find.text('Grille'), findsOneWidget);
    expect(find.text('Liste'), findsOneWidget);
  });

  testWidgets('affiche une carte par classe et bascule sans erreur', (
    tester,
  ) async {
    await pumpView(tester);

    expect(find.text('Classe A'), findsOneWidget);
    expect(find.text('Classe B'), findsOneWidget);

    await tester.tap(find.text('Liste'));
    await tester.pumpAndSettle();

    expect(find.text('Classe A'), findsOneWidget);
    expect(find.text('Classe B'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
