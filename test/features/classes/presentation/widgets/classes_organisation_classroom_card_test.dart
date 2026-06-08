import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_classroom_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Classroom buildClassroom({required String name, required int capacity}) =>
      Classroom(
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
        totalCount: 0,
        femaleCount: 0,
        maleCount: 0,
      );

  List<ClassroomMember> buildMembers({required int male, required int female}) {
    final list = <ClassroomMember>[];
    for (var i = 0; i < male; i++) {
      list.add(_member('m$i', ClassroomMemberGender.male));
    }
    for (var i = 0; i < female; i++) {
      list.add(_member('f$i', ClassroomMemberGender.female));
    }
    return list;
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required Classroom classroom,
    required List<ClassroomMember> members,
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
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: 360,
                child: ClassesOrganisationClassroomCard(
                  classroom: classroom,
                  members: members,
                  isReassigning: false,
                  reassigningMemberId: '',
                  onTransferTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  double progressValue(WidgetTester tester) => tester
      .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
      .value!;

  Color? progressColor(WidgetTester tester) => tester
      .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
      .color;

  testWidgets('en-tête : lettre, libellé, capacité et pastilles G/F', (
    tester,
  ) async {
    await pumpCard(
      tester,
      classroom: buildClassroom(name: 'A', capacity: 40),
      members: buildMembers(male: 6, female: 4),
    );

    expect(find.text('A'), findsOneWidget); // pastille-lettre
    expect(find.text('Classe A'), findsOneWidget);
    expect(find.text('10 élèves · capacité 40'), findsOneWidget);
    expect(find.text('G · 6'), findsOneWidget);
    expect(find.text('F · 4'), findsOneWidget);
  });

  testWidgets('barre bleue quand loin de la capacité', (tester) async {
    await pumpCard(
      tester,
      classroom: buildClassroom(name: 'A', capacity: 40),
      members: buildMembers(male: 5, female: 5),
    );

    expect(progressValue(tester), closeTo(0.25, 0.001));
    expect(progressColor(tester), AppColors.bleuArdoise);
    expect(find.text('complet'), findsNothing);
  });

  testWidgets('barre ambre à partir de 85 %', (tester) async {
    await pumpCard(
      tester,
      classroom: buildClassroom(name: 'B', capacity: 40),
      members: buildMembers(male: 18, female: 18),
    );

    expect(progressValue(tester), closeTo(0.9, 0.001));
    expect(progressColor(tester), AppColors.warning);
    expect(find.text('complet'), findsNothing);
  });

  testWidgets('barre rouge + « complet » quand pleine', (tester) async {
    await pumpCard(
      tester,
      classroom: buildClassroom(name: 'C', capacity: 4),
      members: buildMembers(male: 2, female: 2),
    );

    expect(progressValue(tester), closeTo(1.0, 0.001));
    expect(progressColor(tester), AppColors.danger);
    expect(find.text('complet'), findsOneWidget);
  });

  testWidgets('classe vide : message dédié, aucune tuile élève', (
    tester,
  ) async {
    await pumpCard(
      tester,
      classroom: buildClassroom(name: 'D', capacity: 40),
      members: const [],
    );

    expect(find.text('Aucun élève dans cette classe.'), findsOneWidget);
  });
}

ClassroomMember _member(String id, ClassroomMemberGender gender) =>
    ClassroomMember(
      id: id,
      studentId: 's-$id',
      classroomId: 'c',
      academicYearId: 'y',
      studentFirstName: 'First$id',
      studentLastName: 'Last$id',
      studentMiddleName: null,
      studentGender: gender,
    );
