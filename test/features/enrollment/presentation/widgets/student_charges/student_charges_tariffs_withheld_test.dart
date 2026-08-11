import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_empty_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_list.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_step_body.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_step_controller.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

/// ADR-014 — le serveur retire la grille tarifaire du référentiel pour qui n'a
/// pas `finance.grid.read`. Rien ne peut alors être calculé localement, et une
/// liste de créances vide cesse de vouloir dire « cet élève ne doit rien ».
///
/// Sans distinction, le secrétaire validait l'étape en annonçant 0 F : la
/// famille repartait sans régler, le serveur régénérait les créances à l'ACK,
/// et l'encaissement du jour était manqué.
void main() {
  final AppLocalizations l10n = AppLocalizationsFr();

  const charge = StudentCharge(
    id: 'c1',
    studentId: 'stu-1',
    academicYearId: 'y1',
    schoolLevelId: 'lvl-1',
    schoolLevelGroupId: 'grp-1',
    feeTariffId: 't1',
    feeCode: 'TUITION',
    label: 'Frais de scolarité',
    expectedAmountInCents: 150000,
    amountPaidInCents: 0,
    currency: 'CDF',
    status: StudentChargeStatus.due,
  );

  Widget host({
    required List<StudentCharge> charges,
    required bool tariffsWithheld,
    bool feeGridUnavailable = false,
  }) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: StudentChargesStepBody(
          l10n: l10n,
          status: StudentChargesStatus.success,
          errorType: StudentChargesErrorType.unknown,
          studentCharges: charges,
          amountControllers: const {},
          amountErrors: const {},
          isEditable: false,
          onRetry: () {},
          onAmountChanged: (_) {},
          tariffsWithheld: tariffsWithheld,
          feeGridUnavailable: feeGridUnavailable,
        ),
      ),
    ),
  );

  group('affichage', () {
    testWidgets('grille caviardée + liste vide → explication, pas « aucune »', (
      tester,
    ) async {
      await tester.pumpWidget(host(charges: const [], tariffsWithheld: true));
      await tester.pumpAndSettle();

      expect(find.byType(StudentChargesEmptyState), findsNothing);
      expect(
        find.textContaining('grille tarifaire'),
        findsOneWidget,
        reason: 'le motif réel doit être nommé',
      );
    });

    testWidgets('droit détenu + liste vide → « aucune charge » légitime', (
      tester,
    ) async {
      await tester.pumpWidget(host(charges: const [], tariffsWithheld: false));
      await tester.pumpAndSettle();

      expect(find.byType(StudentChargesEmptyState), findsOneWidget);
    });

    // Fausse alerte à éviter : si des créances sont là, elles font foi, quel
    // que soit le droit sur la grille dont elles dérivent.
    testWidgets('grille caviardée mais créances présentes → aucune alerte', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(charges: const [charge], tariffsWithheld: true),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('grille tarifaire'), findsNothing);
      expect(find.byType(StudentChargesList), findsOneWidget);
    });
  });

  group('validité de l\'étape', () {
    late StudentChargesStepController controller;

    setUp(() => controller = StudentChargesStepController());
    tearDown(() => controller.dispose());

    bool recompute({bool withheld = false, bool gridUnavailable = false}) {
      controller.recomputeFormState(
        canFetch: true,
        canEditAmounts: true,
        currentStatus: StudentChargesStatus.success,
        parseAmount: (raw) => double.tryParse(raw),
        tariffsWithheld: withheld,
        feeGridUnavailable: gridUnavailable,
      );
      return controller.isValid;
    }

    // Le cœur du défaut : `every` sur une liste vide rend `true`, donc l'étape
    // se validait toute seule et « Continuer » restait offert.
    test('liste vide + grille caviardée → étape INVALIDE', () {
      expect(recompute(withheld: true), isFalse);
    });

    test('liste vide + droit détenu + grille présente → étape valide', () {
      expect(recompute(), isTrue);
    });

    // Droit détenu ne garantit pas donnée présente : sans cette branche,
    // l'étape se validait et « Continuer » restait offert à 0 F.
    test('liste vide + grille absente de l\'appareil → étape INVALIDE', () {
      expect(recompute(gridUnavailable: true), isFalse);
    });

    test('créances présentes → le droit sur la grille ne bloque rien', () {
      controller.syncChargesFromState(const [
        charge,
      ], formatAmount: (amount) => amount.toStringAsFixed(2));

      expect(recompute(withheld: true), isTrue);
    });
  });
}
