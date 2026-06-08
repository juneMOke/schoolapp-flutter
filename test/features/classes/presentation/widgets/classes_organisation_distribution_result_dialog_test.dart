import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_result_medallion.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_distribution_criterion.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_with_members.dart';
import 'package:school_app_flutter/features/classes/domain/entities/level_distribution_overview.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_distribution_result_dialog.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockClassroomBloc extends MockBloc<ClassroomEvent, ClassroomState>
    implements ClassroomBloc {}

void main() {
  late MockClassroomBloc bloc;
  late StreamController<ClassroomState> controller;

  const request = ClassroomDistributionRequested(
    academicYearId: 'year-1',
    schoolLevelGroupId: 'cycle-1',
    schoolLevelId: 'level-1',
    distributionCriterion: ClassroomDistributionCriterion.gender,
  );

  const loadingState = ClassroomState(
    distributionStatus: ClassroomStatus.loading,
  );

  ClassroomWithMembers classroom(String name, int members) =>
      ClassroomWithMembers(
        classroom: Classroom(
          id: 'class-$name',
          schoolLevelGroupId: 'cycle-1',
          schoolLevelId: 'level-1',
          academicYearId: 'year-1',
          name: name,
          capacity: 40,
          teacherId: null,
          teacherFirstName: null,
          teacherLastName: null,
          teacherMiddleName: null,
          totalCount: members,
          femaleCount: 0,
          maleCount: members,
        ),
        members: List.generate(
          members,
          (index) => ClassroomMember(
            id: 'm-$name-$index',
            studentId: 's-$name-$index',
            classroomId: 'class-$name',
            academicYearId: 'year-1',
            studentFirstName: 'First$index',
            studentLastName: 'Last$index',
            studentMiddleName: null,
            studentGender: ClassroomMemberGender.male,
          ),
        ),
      );

  final successState = ClassroomState(
    distributionStatus: ClassroomStatus.success,
    distributionOverviewStatus: ClassroomStatus.success,
    distributionOverview: LevelDistributionOverview(
      unassignedEnrollments: const <EnrollmentSummary>[],
      classrooms: [classroom('A', 2), classroom('B', 1)],
    ),
  );

  const errorState = ClassroomState(
    distributionStatus: ClassroomStatus.failure,
    distributionErrorType: ClassroomErrorType.server,
  );

  setUp(() {
    bloc = MockClassroomBloc();
    controller = StreamController<ClassroomState>.broadcast();
    whenListen(bloc, controller.stream, initialState: loadingState);
  });

  tearDown(() => controller.close());

  Future<void> pumpDialog(
    WidgetTester tester, {
    VoidCallback? onDistributed,
  }) async {
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
          body: Builder(
            builder: (context) => MediaQuery(
              // Neutralise les animations (spin infini du processing) pour des
              // pumps déterministes.
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: BlocProvider<ClassroomBloc>.value(
                value: bloc,
                child: ClassesOrganisationDistributionResultDialog(
                  request: request,
                  levelName: '5e',
                  onDistributed: onDistributed ?? () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Laisse tourner le post-frame callback (dispatch initial de la requête).
    await tester.pump();
  }

  testWidgets('démarre en processing et dispatche la répartition', (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(find.text('Répartition en cours…'), findsOneWidget);
    expect(find.byType(EteeloResultMedallion), findsOneWidget);
    verify(() => bloc.add(request)).called(1);
  });

  testWidgets('au succès : récapitule l\'effectif par classe', (tester) async {
    await pumpDialog(tester);

    controller.add(successState);
    await tester.pump();

    expect(find.text('Répartition réussie'), findsOneWidget);
    expect(find.text('Effectif par classe'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('2 élèves'), findsOneWidget);
  });

  testWidgets('au succès : applique les effets de bord (onDistributed)', (
    tester,
  ) async {
    var distributed = 0;
    await pumpDialog(tester, onDistributed: () => distributed++);

    controller.add(successState);
    await tester.pump();

    expect(distributed, 1);
  });

  testWidgets('à l\'échec : carte eteelo + Réessayer relance la répartition', (
    tester,
  ) async {
    await pumpDialog(tester);

    controller.add(errorState);
    await tester.pump();

    expect(find.byType(EteeloErrorResult), findsOneWidget);
    expect(find.text('Échec de la répartition'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pump();

    // Dispatch initial + relance = 2 fois.
    verify(() => bloc.add(request)).called(2);
  });
}
