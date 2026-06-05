import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_chip.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_result_card.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_result_card.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget buildHarness(Widget child) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(child: SizedBox(width: 360, child: child)),
      ),
    );
  }

  const enrollment = EnrollmentSummary(
    enrollmentId: 'enr-1',
    enrollmentCode: 'ENR-001',
    status: 'VALIDATED',
    student: StudentSummary(
      id: 'stu-1',
      firstName: 'Jean',
      lastName: 'Kanku',
      surname: 'Mbuyi',
      dateOfBirth: '2012-05-20',
      gender: Gender.male,
    ),
  );

  testWidgets('adapte EnrollmentSummary vers la primitive core attendue', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(EnrollmentResultCard(enrollment: enrollment, onTap: () {})),
    );

    expect(find.byType(EteeloResultCard), findsOneWidget);
    expect(find.byType(EteeloChip), findsOneWidget);
    expect(find.text('Kanku'), findsOneWidget);
    expect(find.text('Jean'), findsOneWidget);
    expect(find.text('20/05/2012'), findsOneWidget);
    expect(find.byIcon(Icons.cake_outlined), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);

    final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
    expect(badge.style, StatusBadgeStyle.filled);
  });

  testWidgets('expose un libellé sémantique localisé et déclenche onTap', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    var tapped = false;
    await tester.pumpWidget(
      buildHarness(
        EnrollmentResultCard(
          enrollment: enrollment,
          onTap: () => tapped = true,
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Ouvrir la fiche de Kanku Jean, statut Validé'),
      findsOneWidget,
    );

    await tester.tap(find.byType(EnrollmentResultCard));
    await tester.pump();

    expect(tapped, isTrue);
    handle.dispose();
  });
}
