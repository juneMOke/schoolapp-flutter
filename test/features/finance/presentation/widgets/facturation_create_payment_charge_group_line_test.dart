import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_charge_entry.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_charge_group_entry.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_charge_group_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La ligne d'une nature à l'encaissement (GE-2).
void main() {
  StudentCharge charge({
    required String id,
    String? tariffCode,
    double expected = 50000,
    double paid = 0,
  }) => StudentCharge(
    id: id,
    studentId: 's-1',
    academicYearId: 'y-1',
    schoolLevelId: 'lvl-1',
    schoolLevelGroupId: 'grp-1',
    feeTariffId: 't-$id',
    feeTariffCode: tariffCode,
    feeCode: 'TUITION',
    label: 'Minerval',
    expectedAmountInCents: expected,
    amountPaidInCents: paid,
    currency: 'CDF',
    status: StudentChargeStatus.due,
  );

  FacturationChargeGroupEntry groupOf(List<StudentCharge> charges) {
    final entries = [for (final c in charges) FacturationChargeEntry(c)];
    final group = groupPayableEntries(entries).single;
    addTearDown(() {
      group.dispose();
      for (final entry in entries) {
        entry.dispose();
      }
    });
    return group;
  }

  Future<void> pump(
    WidgetTester tester,
    FacturationChargeGroupEntry group, {
    String? schoolTitle,
    ValueChanged<bool>? onSelectedChanged,
    VoidCallback? onSettleAll,
    VoidCallback? onToggleExpanded,
    List<Widget> trancheLines = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: FacturationCreatePaymentChargeGroupLine(
              group: group,
              schoolTitle: schoolTitle,
              onSelectedChanged: onSelectedChanged ?? (_) {},
              onSettleAll: onSettleAll ?? () {},
              onAmountEdited: () {},
              onToggleExpanded: onToggleExpanded ?? () {},
              trancheLines: trancheLines,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('nomme la nature et annonce ses tranches RESTANTES', (
    tester,
  ) async {
    // « restantes », et pas « tranches » : la fiche annonce le total de la
    // grille, cet écran ne monte que ce qui reste à payer.
    await pump(
      tester,
      groupOf([
        charge(id: '1', tariffCode: 'T1'),
        charge(id: '2', tariffCode: 'T2'),
        charge(id: '3', tariffCode: 'T3'),
      ]),
    );

    expect(find.text('Frais de scolarité · 3 tranches'), findsOneWidget);
    expect(find.text('3 tranches restantes'), findsOneWidget);
  });

  testWidgets('prend le titre de l\'école quand il est connu', (tester) async {
    await pump(
      tester,
      groupOf([charge(id: '1'), charge(id: '2')]),
      schoolTitle: 'Frais scolaires annuels',
    );

    expect(find.text('Frais scolaires annuels · 2 tranches'), findsOneWidget);
  });

  testWidgets('non coché : aucun champ de montant', (tester) async {
    await pump(tester, groupOf([charge(id: '1'), charge(id: '2')]));

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Tout solder'), findsNothing);
  });

  testWidgets('coché : le champ du groupe et « Tout solder » apparaissent', (
    tester,
  ) async {
    final group = groupOf([charge(id: '1'), charge(id: '2')]);
    group.applyCascade('600');

    await pump(tester, group);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Tout solder'), findsOneWidget);
  });

  testWidgets('MONTRE la ventilation, même replié', (tester) async {
    // Le caissier valide une répartition : la lui cacher lui ferait signer ce
    // qu'il n'a pas vu, et c'est elle qui partira sur la note de perception.
    final group = groupOf([
      charge(id: '1', tariffCode: 'T1'),
      charge(id: '2', tariffCode: 'T2'),
      charge(id: '3', tariffCode: 'T3'),
    ]);
    group.applyCascade('1200');

    await pump(tester, group);

    expect(group.expanded, isFalse);
    expect(
      find.textContaining('T1').first,
      findsOneWidget,
      reason: 'la ventilation doit nommer les tranches atteintes',
    );
    expect(find.textContaining('Ventilation'), findsOneWidget);
  });

  testWidgets('rien de ventilé : aucune mention vide', (tester) async {
    final group = groupOf([charge(id: '1'), charge(id: '2')]);
    group.tranches.first.selected = true;

    await pump(tester, group);

    expect(find.textContaining('Ventilation'), findsNothing);
  });

  testWidgets('une nature d\'une seule tranche n\'offre pas de dépliant', (
    tester,
  ) async {
    await pump(tester, groupOf([charge(id: '1')]));

    expect(find.text('Détailler les tranches'), findsNothing);
  });

  testWidgets('déplié : les lignes de tranche sont rendues', (tester) async {
    final group = groupOf([charge(id: '1'), charge(id: '2')])..expanded = true;

    await pump(
      tester,
      group,
      trancheLines: const [Text('tranche-1'), Text('tranche-2')],
    );

    expect(find.text('tranche-1'), findsOneWidget);
    expect(find.text('tranche-2'), findsOneWidget);
    expect(find.text('Replier les tranches'), findsOneWidget);
  });

  testWidgets('replié : les lignes de tranche ne sont pas rendues', (
    tester,
  ) async {
    await pump(
      tester,
      groupOf([charge(id: '1'), charge(id: '2')]),
      trancheLines: const [Text('tranche-1')],
    );

    expect(find.text('tranche-1'), findsNothing);
  });

  testWidgets(
    'quand les TRANCHES commandent, le champ du groupe est en lecture seule',
    (tester) async {
      // Deux vérités pour un montant, c'est un montant qu'on ne sait plus lire.
      final group = groupOf([charge(id: '1'), charge(id: '2')]);
      group.applyCascade('600');
      group.groupIsSource = false;

      await pump(tester, group);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.readOnly, isTrue);
    },
  );

  testWidgets('le clic du dépliant remonte, sans toucher la sélection', (
    tester,
  ) async {
    var toggled = 0;
    var selectionChanged = 0;
    await pump(
      tester,
      groupOf([charge(id: '1'), charge(id: '2')]),
      onToggleExpanded: () => toggled++,
      onSelectedChanged: (_) => selectionChanged++,
    );

    await tester.tap(find.text('Détailler les tranches'));
    await tester.pumpAndSettle();

    expect(toggled, 1);
    expect(selectionChanged, 0);
  });

  testWidgets('la case coche le groupe entier', (tester) async {
    bool? received;
    await pump(
      tester,
      groupOf([charge(id: '1'), charge(id: '2')]),
      onSelectedChanged: (value) => received = value,
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(received, isTrue);
  });
}
