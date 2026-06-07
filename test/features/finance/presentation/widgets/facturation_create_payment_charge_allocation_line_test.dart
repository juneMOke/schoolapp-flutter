import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_charge_allocation_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

StudentCharge _charge() => const StudentCharge(
  id: 'c1',
  studentId: 's1',
  academicYearId: 'y1',
  schoolLevelId: 'l1',
  schoolLevelGroupId: 'g1',
  feeTariffId: 't1',
  feeCode: 'TUITION',
  label: 'Frais de scolarité',
  expectedAmountInCents: 500000,
  amountPaidInCents: 200000,
  currency: 'CDF',
  status: StudentChargeStatus.partial,
);

/// Hôte reproduisant le contrat de la modale : coche → pré-remplit le restant.
class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final controller = TextEditingController();
  bool selected = false;

  @override
  void initState() {
    super.initState();
    // Comme la vraie modale : le rebuild est porté par le listener du controller.
    controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FacturationCreatePaymentChargeAllocationLine(
      charge: _charge(),
      selected: selected,
      amountController: controller,
      onSelectedChanged: (v) => setState(() {
        selected = v;
        if (v) {
          controller.text = '3000'; // restant = 5000 − 2000 = 3000
        } else {
          controller.clear();
        }
      }),
      onSettleAll: () => setState(() => controller.text = '3000'),
    );
  }
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      locale: Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: _Host())),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('repliée : libellé + état, sans champ montant', (tester) async {
    await _pump(tester);

    expect(find.text('Frais de scolarité'), findsOneWidget);
    // État replié : « Dû / Déjà payé / Restant » présents.
    expect(find.textContaining('Restant'), findsOneWidget);
    expect(find.textContaining('Déjà payé'), findsOneWidget);
    expect(find.text('Tout solder'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cochée : pré-remplit le restant et solde la ligne', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    expect(find.text('Tout solder'), findsOneWidget);
    // Restant après = 0 → chip « Soldé ».
    expect(find.text('Soldé'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dépassement : affiche l\'avertissement ambre', (tester) async {
    await _pump(tester);

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '9000');
    await tester.pumpAndSettle();

    expect(find.textContaining('ramené au restant'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
