import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

StudentCharge _charge({
  StudentChargeStatus status = StudentChargeStatus.partial,
  double expected = 30000,
  double paid = 18000,
  String label = 'Frais de scolarité',
  String feeCode = 'TUITION',
  String? feeTariffCode,
}) {
  return StudentCharge(
    id: 'c1',
    studentId: 's1',
    academicYearId: 'y1',
    schoolLevelId: 'l1',
    schoolLevelGroupId: 'g1',
    feeTariffId: 't1',
    feeTariffCode: feeTariffCode,
    feeCode: feeCode,
    label: label,
    expectedAmountInCents: expected,
    amountPaidInCents: paid,
    currency: 'USD',
    status: status,
  );
}

Future<void> _pumpInPageBackground(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(child: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'FacturationChargeLine se rend dans AppPageBackground sans erreur de layout',
    (tester) async {
      await _pumpInPageBackground(
        tester,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FacturationChargeLine(charge: _charge(), onViewRequested: () {}),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(FacturationChargeLine), findsOneWidget);
    },
  );

  testWidgets(
    'FacturationChargeLine: liste de plusieurs lignes (tous statuts)',
    (tester) async {
      await _pumpInPageBackground(
        tester,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final status in StudentChargeStatus.values)
              FacturationChargeLine(
                charge: _charge(status: status),
                onViewRequested: () {},
              ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byType(FacturationChargeLine),
        findsNWidgets(StudentChargeStatus.values.length),
      );
    },
  );

  /// La ligne affichait la NATURE (« Frais de scolarité » pour tout `TUITION`) :
  /// sur un minerval en sept tranches, sept lignes identiques, sept montants
  /// différents, et rien pour savoir laquelle on ouvre.
  group('la ligne nomme la tranche', () {
    testWidgets('libellé du référentiel + code du tarif', (tester) async {
      await _pumpInPageBackground(
        tester,
        FacturationChargeLine(
          charge: _charge(
            label: 'Organisation matériel examens — 2/3',
            feeCode: 'EXAMINATION',
            feeTariffCode: 'OM2',
          ),
          onViewRequested: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Organisation matériel examens — 2/3 (OM2)'),
        findsOneWidget,
      );
    });

    /// Une grille simple n'a pas de code à saisir et le serveur y met la nature.
    /// « Frais de scolarité (TUITION) » serait du bruit sur toutes les écoles,
    /// pour ne rien distinguer nulle part.
    testWidgets('code égal à la nature → pas de parenthèse', (tester) async {
      await _pumpInPageBackground(
        tester,
        FacturationChargeLine(
          charge: _charge(feeTariffCode: 'TUITION'),
          onViewRequested: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Frais de scolarité'), findsOneWidget);
    });

    testWidgets('sans code → le libellé seul', (tester) async {
      await _pumpInPageBackground(
        tester,
        FacturationChargeLine(charge: _charge(), onViewRequested: () {}),
      );
      await tester.pumpAndSettle();

      expect(find.text('Frais de scolarité'), findsOneWidget);
    });
  });
}
