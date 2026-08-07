import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_unassigned_members_section.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  EnrollmentSummary enrollment(String id, Gender gender) => EnrollmentSummary(
    enrollmentId: 'enrollment-$id',
    enrollmentCode: 'MAT-$id',
    status: 'COMPLETED',
    enrollmentType: 'FIRST_REGISTRATION',
    student: StudentSummary(
      id: 's-$id',
      firstName: 'First$id',
      lastName: 'Last$id',
      surname: '',
      dateOfBirth: '2015-01-01',
      gender: gender,
    ),
  );

  Future<void> pumpSection(
    WidgetTester tester, {
    String assigningEnrollmentId = '',
    ValueChanged<ClassroomMemberReassignIntent>? onTransferTap,
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
            child: ClassesOrganisationUnassignedMembersSection(
              count: 2,
              enrollments: [
                enrollment('1', Gender.male),
                enrollment('2', Gender.female),
              ],
              isReassigning: false,
              assigningEnrollmentId: assigningEnrollmentId,
              onTransferTap: onTransferTap ?? (_) {},
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

  // Régression du bug d'endpoint : le geste doit porter l'`enrollmentId` du
  // dossier, seule identité acceptée par le POST d'affectation — un
  // `classroomMemberId` (que le non-réparti n'a pas) donnait un 404.
  testWidgets('« Affecter » émet un intent portant l\'enrollmentId', (
    tester,
  ) async {
    ClassroomMemberReassignIntent? captured;
    await pumpSection(tester, onTransferTap: (intent) => captured = intent);

    await tester.tap(find.widgetWithText(FilledButton, 'Affecter').first);
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured!.enrollmentId, 'enrollment-1');
    expect(captured!.studentId, 's-1');
    // Mode affectation : aucune classe d'origine.
    expect(captured!.classroomId, isNull);
  });

  testWidgets('la tuile en cours d\'affectation est repérée par son dossier', (
    tester,
  ) async {
    await pumpSection(tester, assigningEnrollmentId: 'enrollment-2');
    await tester.pump();

    // Le spinner remplace l'icône de la seule tuile concernée.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
