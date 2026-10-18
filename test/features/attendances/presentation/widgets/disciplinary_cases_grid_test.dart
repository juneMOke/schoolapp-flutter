import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/offline_disciplinary_case.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_card.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_cases_state_body.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Sur grand écran, les dossiers se rangent en deux colonnes.
///
/// Empilée sur 1180 dp, une carte collait son contenu à gauche et rejetait ses
/// gestes à l'extrême droite.
void main() {
  OfflineDisciplinaryCase dossier(String id) => OfflineDisciplinaryCase(
    id: id,
    studentId: 's1',
    studentFirstName: 'John',
    studentLastName: 'Doe',
    studentGender: StudentGender.male,
    academicYearId: 'y1',
    disciplinaryCaseDate: DateTime(2026, 1, 14),
    title: 'Dossier $id',
    status: DisciplinaryStatus.open,
    content: 'Bagarre avec un autre élève.',
    category: DisciplinaryCategory.fighting,
    severity: DisciplinarySeverity.serious,
    updatedAt: 1000,
  );

  Future<void> pump(WidgetTester tester, double width) => tester.pumpWidget(
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
          child: SizedBox(
            width: width,
            child: DisciplinaryCasesStateBody(
              status: DisciplinaryCasesBodyStatus.success,
              cases: [dossier('a'), dossier('b')],
              errorType: DisciplinaryCaseErrorType.none,
            ),
          ),
        ),
      ),
    ),
  );

  Offset topLeftOf(WidgetTester tester, int index) =>
      tester.getTopLeft(find.byType(DisciplinaryCaseCard).at(index));

  testWidgets('grand écran : deux dossiers côte à côte', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1300, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pump(tester, 1180);
    await tester.pump(const Duration(milliseconds: 16));

    expect(topLeftOf(tester, 1).dy, topLeftOf(tester, 0).dy);
    expect(topLeftOf(tester, 1).dx, greaterThan(topLeftOf(tester, 0).dx));
  });

  testWidgets('tablette étroite : les dossiers s\'empilent', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pump(tester, 700);
    await tester.pump(const Duration(milliseconds: 16));

    expect(topLeftOf(tester, 1).dy, greaterThan(topLeftOf(tester, 0).dy));
  });
}
