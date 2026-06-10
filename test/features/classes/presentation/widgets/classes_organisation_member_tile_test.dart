import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_member_tile.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  const member = ClassroomMember(
    id: 'member-1',
    studentId: 'student-1',
    classroomId: 'c1',
    academicYearId: 'y',
    studentFirstName: 'Jane',
    studentLastName: 'Doe',
    studentMiddleName: 'K',
    studentGender: ClassroomMemberGender.female,
  );

  Future<ClassroomMemberReassignIntent?> pumpTile(
    WidgetTester tester, {
    required ClassesOrganisationMemberAction action,
    String? classroomId,
    bool isReassigning = false,
    bool isCurrentReassigningMember = false,
  }) async {
    ClassroomMemberReassignIntent? captured;
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
          body: Center(
            child: SizedBox(
              width: 360,
              child: ClassesOrganisationMemberTile(
                member: member,
                classroomId: classroomId,
                isReassigning: isReassigning,
                isCurrentReassigningMember: isCurrentReassigningMember,
                action: action,
                onTransferTap: (intent) => captured = intent,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return captured;
  }

  testWidgets('identité : « Nom Post-nom » au-dessus, « Prénom » dessous', (
    tester,
  ) async {
    await pumpTile(
      tester,
      action: ClassesOrganisationMemberAction.transfer,
      classroomId: 'c1',
    );

    expect(find.text('Doe K'), findsOneWidget);
    expect(find.text('Jane'), findsOneWidget);
    expect(find.byIcon(Icons.female), findsOneWidget); // marqueur venus
  });

  testWidgets('variante classe : bouton « Transférer » contour, intent porté', (
    tester,
  ) async {
    ClassroomMemberReassignIntent? captured;
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
          body: Center(
            child: SizedBox(
              width: 360,
              child: ClassesOrganisationMemberTile(
                member: member,
                classroomId: 'c1',
                isReassigning: false,
                isCurrentReassigningMember: false,
                action: ClassesOrganisationMemberAction.transfer,
                onTransferTap: (intent) => captured = intent,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.widgetWithText(OutlinedButton, 'Transférer'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Transférer'));
    expect(captured, isNotNull);
    expect(captured!.classroomId, 'c1');
    expect(captured!.classroomMemberId, 'member-1');
    expect(captured!.studentDisplayName, 'Doe K Jane');
  });

  testWidgets(
    'variante non réparti : bouton « Affecter » plein, classroom null',
    (tester) async {
      ClassroomMemberReassignIntent? captured;
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
            body: Center(
              child: SizedBox(
                width: 360,
                child: ClassesOrganisationMemberTile(
                  member: member,
                  classroomId: null,
                  isReassigning: false,
                  isCurrentReassigningMember: false,
                  action: ClassesOrganisationMemberAction.assign,
                  onTransferTap: (intent) => captured = intent,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.widgetWithText(FilledButton, 'Affecter'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Affecter'));
      expect(captured, isNotNull);
      expect(captured!.classroomId, isNull);
    },
  );

  testWidgets('transfert en cours : spinner + bouton inactif', (tester) async {
    await pumpTile(
      tester,
      action: ClassesOrganisationMemberAction.transfer,
      classroomId: 'c1',
      isReassigning: true,
      isCurrentReassigningMember: true,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull);
  });
}
