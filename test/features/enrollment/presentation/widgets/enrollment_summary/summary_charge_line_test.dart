import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_charge_line.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

/// Le récapitulatif est ce que le secrétariat relit **avant de valider** un
/// dossier. Il portait sa propre cascade de nommage — une troisième, différente
/// de celle du guichet ET de celle de l'étape « Frais » — et annonçait donc des
/// lignes que les deux autres écrans nommaient autrement.
void main() {
  const baseCharge = StudentCharge(
    id: 'c1',
    studentId: 's1',
    academicYearId: 'y1',
    schoolLevelId: 'l1',
    schoolLevelGroupId: 'g1',
    feeTariffId: 't1',
    feeCode: 'TUITION',
    label: 'Frais de scolarité',
    expectedAmountInCents: 45000000,
    amountPaidInCents: 0,
    currency: 'CDF',
    status: StudentChargeStatus.due,
  );

  Future<void> pump(WidgetTester tester, StudentCharge charge) =>
      tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SummaryChargeLine(charge: charge)),
        ),
      );

  testWidgets('libellé du référentiel + code du tarif', (tester) async {
    await pump(
      tester,
      baseCharge.copyWith(
        feeCode: 'EXAMINATION',
        label: 'Organisation matériel examens — 2/3',
        feeTariffCode: 'OM2',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Organisation matériel examens — 2/3 (OM2)'),
      findsOneWidget,
    );
  });

  /// Le cas qui a changé de sens : `TUITION` étant une nature CONNUE, la ligne
  /// affichait sa traduction et ne lisait jamais le libellé du référentiel.
  testWidgets('le libellé prime sur la nature, même connue', (tester) async {
    await pump(tester, baseCharge.copyWith(label: 'Minerval — 1/7'));
    await tester.pumpAndSettle();

    expect(find.text('Minerval — 1/7'), findsOneWidget);
  });

  testWidgets('code égal à la nature → pas de parenthèse', (tester) async {
    await pump(tester, baseCharge.copyWith(feeTariffCode: 'TUITION'));
    await tester.pumpAndSettle();

    expect(find.text('Frais de scolarité'), findsOneWidget);
  });

  /// Créance *ad hoc* sans libellé : la nature localisée reste le dernier
  /// recours — un frais sans nom du tout serait pire que trop générique.
  testWidgets('sans libellé → repli sur la nature localisée', (tester) async {
    await pump(tester, baseCharge.copyWith(label: '   '));
    await tester.pumpAndSettle();

    expect(
      find.text(AppLocalizationsFr().studentChargeFeeCodeTuition),
      findsOneWidget,
    );
  });
}
