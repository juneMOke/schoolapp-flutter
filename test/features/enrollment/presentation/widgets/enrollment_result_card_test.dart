import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_chip.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_result_card.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
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

  testWidgets('dossier RE avec brouillon local affiche « En cours » (pas « '
      'Pré-inscrit »), quel que soit le statut brut porté', (tester) async {
    const reDraft = EnrollmentSummary(
      enrollmentId: 'enr-re',
      enrollmentCode: 'RE-001',
      status: 'PRE_REGISTERED',
      enrollmentType: 'RE_ENROLLMENT',
      syncState: SyncState.draft,
      student: StudentSummary(
        id: 'stu-2',
        firstName: 'Amina',
        lastName: 'Moke',
        surname: 'Junior',
        dateOfBirth: '2015-04-02',
        gender: Gender.female,
      ),
    );

    await tester.pumpWidget(
      buildHarness(EnrollmentResultCard(enrollment: reDraft, onTap: () {})),
    );

    // Pastille pilotée par le TYPE + l'axe syncState (isLocalDraft), jamais
    // par le statut métier brut : « En cours » remplace « Pré-inscrit ».
    expect(find.text('En cours'), findsOneWidget);
    expect(find.text('Pré-inscrit'), findsNothing);
  });

  testWidgets(
    'dossier RE finalisé/synchronisé (pas de brouillon local) affiche « '
    'Réinscrit », quel que soit le statut brut porté',
    (tester) async {
      const reFinalized = EnrollmentSummary(
        enrollmentId: 'enr-re-2',
        enrollmentCode: 'RE-002',
        status: 'IN_PROGRESS',
        enrollmentType: 'RE_ENROLLMENT',
        syncState: SyncState.synced,
        student: StudentSummary(
          id: 'stu-4',
          firstName: 'Amina',
          lastName: 'Moke',
          surname: 'Junior',
          dateOfBirth: '2015-04-02',
          gender: Gender.female,
        ),
      );

      await tester.pumpWidget(
        buildHarness(
          EnrollmentResultCard(enrollment: reFinalized, onTap: () {}),
        ),
      );

      expect(find.text('Réinscrit'), findsOneWidget);
      expect(find.text('En cours'), findsNothing);
    },
  );

  testWidgets(
    'candidat de réinscription (enrollmentId vide, PENDING) affiche « À '
    'réinscrire », pas « En Attente »',
    (tester) async {
      const candidate = EnrollmentSummary(
        enrollmentId: '',
        enrollmentCode: 'KIN-2025-0001',
        status: 'PENDING',
        student: StudentSummary(
          id: 'stu-3',
          firstName: 'Amina',
          lastName: 'Moke',
          surname: 'Junior',
          dateOfBirth: '2015-04-02',
          gender: Gender.female,
        ),
      );

      await tester.pumpWidget(
        buildHarness(EnrollmentResultCard(enrollment: candidate, onTap: () {})),
      );

      // Candidat non commencé : « À réinscrire » remplace le statut brut
      // PENDING (« En Attente »).
      expect(find.text('À réinscrire'), findsOneWidget);
      expect(find.text('En Attente'), findsNothing);
    },
  );

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
