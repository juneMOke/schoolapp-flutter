import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_row.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  late TextEditingController controller;

  setUp(() {
    controller = TextEditingController(text: '150 000');
  });

  tearDown(() {
    controller.dispose();
  });

  const baseCharge = StudentCharge(
    id: 'c1',
    studentId: 's1',
    academicYearId: 'y1',
    schoolLevelId: 'l1',
    schoolLevelGroupId: 'g1',
    feeTariffId: 't1',
    feeCode: 'TUITION',
    label: 'Frais de scolarité',
    expectedAmountInCents: 15000000,
    amountPaidInCents: 0,
    currency: 'CDF',
    status: StudentChargeStatus.due,
  );

  Widget harness(StudentCharge charge) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: StudentChargeRow(
        studentCharge: charge,
        amountController: controller,
        isEditable: false,
        currency: 'CDF',
        amountErrorText: null,
        onAmountChanged: (_) {},
      ),
    ),
  );

  testWidgets(
    'dueAt renseigné → affiche la date d\'échéance au lieu du code frais',
    (tester) async {
      final charge = baseCharge.copyWith(dueAt: '2026-09-30');

      await tester.pumpWidget(harness(charge));

      expect(find.text('Échéance : 30 sept. 2026'), findsOneWidget);
      expect(find.text('TUITION'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dueAt absent → repli sur le code frais (comportement existant)',
    (tester) async {
      await tester.pumpWidget(harness(baseCharge));

      expect(find.text('TUITION'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  /// L'étape « Frais » portait une cascade INVERSE de celle du guichet : la
  /// nature d'abord, le libellé seulement si la nature était inconnue. Sur un
  /// minerval en sept tranches, elle affichait donc sept fois « Minerval ».
  group('la ligne nomme la tranche', () {
    testWidgets('libellé du référentiel + code du tarif', (tester) async {
      await tester.pumpWidget(
        harness(
          baseCharge.copyWith(
            feeCode: 'EXAMINATION',
            label: 'Organisation matériel examens — 2/3',
            feeTariffCode: 'OM2',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Organisation matériel examens — 2/3 (OM2)'),
        findsOneWidget,
      );
    });

    /// Le cas qui a changé de sens : avant, `TUITION` étant une nature CONNUE,
    /// la ligne affichait sa traduction et le libellé du référentiel n'était
    /// jamais lu. C'est désormais l'inverse.
    testWidgets('le libellé prime sur la nature, même connue', (tester) async {
      await tester.pumpWidget(
        harness(baseCharge.copyWith(label: 'Minerval — 1/7')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minerval — 1/7'), findsOneWidget);
    });

    testWidgets('code égal à la nature → pas de parenthèse', (tester) async {
      await tester.pumpWidget(
        harness(baseCharge.copyWith(feeTariffCode: 'TUITION')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Frais de scolarité'), findsOneWidget);
    });
  });
}
