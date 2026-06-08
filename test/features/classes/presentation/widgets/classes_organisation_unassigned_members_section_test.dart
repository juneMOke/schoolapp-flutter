import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_unassigned_members_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  ClassroomMember member(String id, ClassroomMemberGender gender) =>
      ClassroomMember(
        id: id,
        studentId: 's-$id',
        classroomId: '',
        academicYearId: 'y',
        studentFirstName: 'First$id',
        studentLastName: 'Last$id',
        studentMiddleName: null,
        studentGender: gender,
      );

  Future<void> pumpSection(WidgetTester tester) async {
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
            child: ClassesOrganisationUnassignedMembersSection(
              count: 2,
              members: [
                member('1', ClassroomMemberGender.male),
                member('2', ClassroomMemberGender.female),
              ],
              isReassigning: false,
              reassigningMemberId: '',
              onTransferTap: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('section ambre : titre, compteur, médaillon alerte', (
    tester,
  ) async {
    await pumpSection(tester);

    expect(find.text('Élèves non répartis'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // gros compteur
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('une action « Affecter » par élève non réparti', (tester) async {
    await pumpSection(tester);

    expect(find.widgetWithText(FilledButton, 'Affecter'), findsNWidgets(2));
  });
}
