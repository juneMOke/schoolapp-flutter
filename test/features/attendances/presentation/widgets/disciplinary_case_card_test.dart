import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_summary.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(child: SizedBox(width: 560, child: child)),
    ),
  );

  DisciplinaryCaseSummary buildCase({
    DisciplinaryCaseStatus status = DisciplinaryCaseStatus.open,
  }) => DisciplinaryCaseSummary(
    id: 'c1',
    studentId: 's1',
    studentFirstName: 'John',
    studentLastName: 'Doe',
    studentGender: StudentGender.male,
    academicYearId: 'y1',
    title: 'Altercation dans la cour',
    status: status,
    content: 'Bagarre avec un autre élève.',
    category: DisciplinaryCategory.fighting,
    severity: DisciplinarySeverity.serious,
    sanction: DisciplinarySanction.parentsSummoned,
    createdAt: DateTime(2026, 1, 14),
  );

  testWidgets('rend gravité, titre, catégorie, statut, sanction + action', (
    tester,
  ) async {
    var advanced = false;
    await tester.pumpWidget(
      host(
        DisciplinaryCaseCard(
          caseData: buildCase(),
          onAdvance: () => advanced = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Gravité Grave'), findsOneWidget);
    expect(find.text('Altercation dans la cour'), findsOneWidget);
    expect(find.text('Bagarre'), findsOneWidget);
    expect(find.text('Ouvert'), findsWidgets); // pastille + frise
    expect(find.text('Convocation des parents'), findsOneWidget);

    // Statut ouvert -> action « Prendre en charge ».
    expect(find.text('Prendre en charge'), findsOneWidget);
    await tester.tap(find.text('Prendre en charge'));
    await tester.pump();
    expect(advanced, isTrue);
  });

  testWidgets('cas clôturé : pas d\'action, « Dossier clôturé »', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        DisciplinaryCaseCard(
          caseData: buildCase(status: DisciplinaryCaseStatus.closed),
          onAdvance: () {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Dossier clôturé'), findsOneWidget);
    expect(find.text('Prendre en charge'), findsNothing);
    expect(find.text('Clôturer'), findsNothing);
  });
}
