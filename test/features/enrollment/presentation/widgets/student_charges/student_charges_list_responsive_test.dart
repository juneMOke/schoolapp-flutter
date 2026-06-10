import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_list.dart';
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

  const charge = StudentCharge(
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

  Widget harness(double width) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: width,
          child: Builder(
            builder: (context) => StudentChargesList(
              studentCharges: const [charge],
              amountControllers: {'c1': controller},
              amountErrors: const {'c1': null},
              isEditable: false,
              l10n: AppLocalizations.of(context)!,
              onAmountChanged: (_) {},
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('Téléphone (<480px) : colonne Actions masquée → 2 colonnes', (
    tester,
  ) async {
    await tester.pumpWidget(harness(360));

    // En-tête « Actions » et icône (lock) de la colonne action absents.
    expect(find.text('Actions'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    // Les deux colonnes restantes restent présentes.
    expect(find.text('Libellé'), findsOneWidget);
    expect(find.text('Montant'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Large (>=480px) : 3 colonnes dont Actions', (tester) async {
    await tester.pumpWidget(harness(700));

    expect(find.text('Actions'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
