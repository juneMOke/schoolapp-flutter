import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_data_table.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _summaries = <EnrollmentSummary>[
  EnrollmentSummary(
    enrollmentId: 'enr-1',
    enrollmentCode: 'ENR-001',
    status: 'VALIDATED',
    student: StudentSummary(
      id: 'stu-1',
      firstName: 'Daniel',
      lastName: 'Kabongo',
      surname: 'Mwamba',
      dateOfBirth: '2012-05-20',
      gender: Gender.male,
    ),
  ),
  EnrollmentSummary(
    enrollmentId: 'enr-2',
    enrollmentCode: 'ENR-002',
    status: 'VALIDATED',
    student: StudentSummary(
      id: 'stu-2',
      firstName: 'Grâce',
      lastName: 'Tshala',
      surname: 'Mbuyi',
      dateOfBirth: '2013-02-10',
      gender: Gender.female,
    ),
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'trois colonnes (Nom / Post-nom / Prénom) + œil, dans AppPageBackground',
    (tester) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppPageBackground(
            child: FacturationDataTable(
              summaries: _summaries,
              showPagination: false,
              onViewRequested: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Trois cellules distinctes par élève (≠ nom complet fusionné).
      expect(find.text('Kabongo'), findsOneWidget);
      expect(find.text('Mwamba'), findsOneWidget);
      expect(find.text('Daniel'), findsOneWidget);
      expect(find.text('Kabongo Mwamba Daniel'), findsNothing);

      // Action « œil » par ligne.
      expect(
        find.byIcon(Icons.visibility_outlined),
        findsNWidgets(_summaries.length),
      );
    },
  );
}
