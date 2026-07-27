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
}
