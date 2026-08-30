import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_previous_academic_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Résumé de l'étape « Année précédente ».
///
/// Le rendu est le dernier endroit où une absence peut se déguiser en valeur.
/// Cette section imprimait « 0% » et « Non » pour un dossier où personne
/// n'avait rien saisi — la fabrication du serveur, reproduite à l'écran par un
/// `?? 0` et un `?? false` posés deux couches plus bas.
void main() {
  EnrollmentDetail detailWith({
    double? previousRate,
    bool? validatedPreviousYear,
    bool formerStudent = false,
    String previousSchoolName = 'École Saint-Joseph',
  }) {
    final empty = EnrollmentDetail.empty();
    return EnrollmentDetail(
      studentDetail: empty.studentDetail,
      parentDetails: empty.parentDetails,
      enrollmentDetail: EnrollmentSchoolDetail(
        id: 'enr-1',
        status: EnrollmentStatus.inProgress,
        academicYearId: 'ay-2026',
        enrollmentCode: '',
        previousSchoolName: previousSchoolName,
        previousAcademicYear: '2025-2026',
        previousSchoolLevelGroup: 'Primaire',
        previousSchoolLevel: 'P3',
        previousRate: previousRate,
        previousRank: null,
        validatedPreviousYear: validatedPreviousYear,
        formerStudent: formerStudent,
        schoolLevelGroupId: '',
        schoolLevelId: '',
      ),
    );
  }

  Widget wrap(EnrollmentDetail detail) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: Scaffold(
      body: SingleChildScrollView(
        child: SummaryPreviousAcademicSection(
          enrollmentDetail: detail,
          onEditRequested: (_) {},
        ),
      ),
    ),
  );

  testWidgets('une moyenne absente s\'affiche « - », jamais « 0% »', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(detailWith()));
    await tester.pump();

    expect(find.text('0.0%'), findsNothing);
    expect(find.text('0%'), findsNothing);
    expect(find.text('-'), findsWidgets);
  });

  /// La contre-épreuve : zéro pour cent EST une note, et doit s'afficher comme
  /// telle. Sans ce test, rendre `—` pour toute valeur fausse passerait pour
  /// une correction.
  testWidgets('une moyenne SAISIE à zéro s\'affiche « 0.0% »', (tester) async {
    await tester.pumpWidget(wrap(detailWith(previousRate: 0)));
    await tester.pump();

    expect(find.text('0.0%'), findsOneWidget);
  });

  testWidgets('une moyenne renseignée s\'affiche telle quelle', (tester) async {
    await tester.pumpWidget(wrap(detailWith(previousRate: 72.5)));
    await tester.pump();

    expect(find.text('72.5%'), findsOneWidget);
  });

  testWidgets('l\'année non renseignée n\'est ni « Oui » ni « Non »', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(detailWith()));
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.text(l10n.yearValidationUnknown), findsOneWidget);
    // L'unique « Non » de l'écran est celui d'« ancien élève », qui est un
    // vrai booléen ; le verdict de l'année, lui, n'en porte aucun.
    expect(find.text(l10n.summaryNo), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StatusBadge),
        matching: find.text(l10n.summaryNo),
      ),
      findsNothing,
    );
    expect(find.text(l10n.summaryYes), findsNothing);
  });

  testWidgets('« Non » reste réservé à un redoublement déclaré', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(detailWith(validatedPreviousYear: false)));
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    // Deux « Non » désormais : celui de l'année, celui d'« ancien élève ».
    expect(find.text(l10n.summaryNo), findsNWidgets(2));
    expect(find.text(l10n.yearValidationUnknown), findsNothing);
  });

  testWidgets('« ancien élève » est repris dans le résumé', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    await tester.pumpWidget(wrap(detailWith(formerStudent: true)));
    await tester.pump();
    expect(find.text(l10n.formerStudentLabel), findsOneWidget);
    expect(find.text(l10n.summaryYes), findsOneWidget);

    await tester.pumpWidget(wrap(detailWith()));
    await tester.pump();
    expect(find.text(l10n.summaryNo), findsOneWidget);
  });
}
