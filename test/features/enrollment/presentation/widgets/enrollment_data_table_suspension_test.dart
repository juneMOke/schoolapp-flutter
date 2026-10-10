import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_row_selection.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_data_table.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

EnrollmentSummary _row(
  String id, {
  String status = 'COMPLETED',
  DateTime? suspendedAt,
}) => EnrollmentSummary(
  enrollmentId: id,
  enrollmentCode: '',
  status: status,
  academicYearId: 'y1',
  suspendedAt: suspendedAt,
  student: StudentSummary(
    id: 's-$id',
    firstName: 'Daniel',
    lastName: 'Nom$id',
    surname: '',
    dateOfBirth: '2012-05-20',
    gender: Gender.male,
  ),
);

void main() {
  Widget harness(Widget child, {EnrollmentRowSelection? selection}) =>
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: EnrollmentRowSelectionScope(
            selection: selection,
            child: SizedBox(width: 1100, child: child),
          ),
        ),
      );

  testWidgets('un élève désactivé porte « Désactivé »', (tester) async {
    await tester.pumpWidget(
      harness(
        EnrollmentDataTable(
          enrollments: [_row('e1', suspendedAt: DateTime(2026, 10, 2))],
          onViewRequested: (_) {},
        ),
      ),
    );
    expect(find.text('Désactivé'), findsOneWidget);
  });

  testWidgets('en mode sélection : une case par ligne, le tap coche', (
    tester,
  ) async {
    final toggled = <String>[];
    await tester.pumpWidget(
      harness(
        EnrollmentDataTable(
          enrollments: [
            _row('e1'),
            _row('e2', status: 'IN_PROGRESS'),
          ],
          onViewRequested: (_) => fail('le tap ne doit pas ouvrir la fiche'),
        ),
        selection: EnrollmentRowSelection(
          selected: const {},
          onToggle: (s) => toggled.add(s.enrollmentId),
        ),
      ),
    );

    expect(find.byType(Checkbox), findsNWidgets(2));
    await tester.tap(find.text('Nome1 Daniel'));
    await tester.tap(find.text('Nome2 Daniel'));
    // Le dossier « En cours » n'est pas éligible : sa ligne ne coche rien.
    expect(toggled, ['e1']);
  });
}
