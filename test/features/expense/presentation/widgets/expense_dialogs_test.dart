import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_message.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_form_seed.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_detail_dialog.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/form/expense_form_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _types = [
  ExpenseType(
    id: 't-elec',
    code: 'ELECTRICITE',
    label: 'Électricité & eau',
    shortLabel: 'Électricité',
    icon: 'power',
    colorHex: '#D9A24E',
    softColorHex: '#FBF3E3',
    defaultCurrency: 'CDF',
    sortOrder: 0,
    active: true,
  ),
  ExpenseType(
    id: 't-four',
    code: 'FOURNITURES',
    label: 'Fournitures (scolaires & bureau)',
    shortLabel: 'Fournitures',
    icon: 'book-marked',
    colorHex: '#1B4D6B',
    softColorHex: '#EBF2F7',
    defaultCurrency: 'USD',
    sortOrder: 1,
    active: true,
  ),
];

final _rate = ExchangeRate(
  base: 'USD',
  quote: 'CDF',
  rateMicros: 2800 * ExchangeRate.scale,
  effectiveFrom: DateTime.utc(2026, 9, 1),
);

final _today = DateTime(2026, 9, 12);

Expense _snel({
  ExpenseStatus status = ExpenseStatus.pending,
  ExpenseSyncState sync = ExpenseSyncState.synced,
  String? code,
}) => Expense(
  id: 'e-1',
  number: 'DEP-0412',
  typeId: 't-elec',
  title: 'Facture SNEL',
  amountInCents: 38500000,
  currency: 'CDF',
  status: status,
  paidOn: status == ExpenseStatus.paid ? _today : null,
  expenseDate: DateTime(2026, 9, 3),
  clientUpdatedAt: DateTime.utc(2026, 9, 3),
  syncState: sync,
  syncErrorCode: code,
);

Future<void> _pumpHost(
  WidgetTester tester,
  Future<void> Function(BuildContext context) open,
) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => open(context),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

/// Le champ par son libellé déclaré — le libellé rendu porte la marque
/// « obligatoire », que `widgetWithText` ne reconnaîtrait pas.
Finder _field(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is EteeloTextInput && w.label == label),
  matching: find.byType(TextField),
);

void main() {
  group('formulaire', () {
    testWidgets('soumettre vide : les deux motifs, et la modale reste', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      ExpenseDraft? draft;
      await _pumpHost(tester, (context) async {
        draft = await showExpenseFormDialog(
          context,
          seed: ExpenseFormSeed.blank(types: _types, today: _today),
          types: _types,
          rate: _rate,
          today: _today,
        );
      });

      await tester.tap(find.text('Enregistrer la dépense'));
      await tester.pump();

      expect(
        find.text('Un intitulé est nécessaire pour retrouver la dépense.'),
        findsOneWidget,
      );
      expect(
        find.text('Indiquez le montant réellement décaissé.'),
        findsOneWidget,
      );
      expect(draft, isNull);
    });

    testWidgets('saisie complète : le brouillon porte des centimes, le premier '
        'type, sa devise et la date du jour', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      ExpenseDraft? draft;
      await _pumpHost(tester, (context) async {
        draft = await showExpenseFormDialog(
          context,
          seed: ExpenseFormSeed.blank(types: _types, today: _today),
          types: _types,
          rate: _rate,
          today: _today,
          recordedByName: 'Moke Junior',
        );
      });

      await tester.enterText(_field('Intitulé de la dépense'), 'Ramettes A4');
      await tester.enterText(_field('Montant'), '142,50');
      await tester.tap(find.text('Enregistrer la dépense'));
      await tester.pumpAndSettle();

      expect(draft, isNotNull);
      expect(draft!.id, isNull);
      expect(draft!.typeId, 't-elec');
      expect(draft!.currency, 'CDF');
      expect(draft!.amountInCents, 14250);
      expect(draft!.expenseDate, _today);
      expect(draft!.recordedByName, 'Moke Junior');
    });

    testWidgets(
      'en francs, avec un taux : l’équivalent se lit sous le montant',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await _pumpHost(
          tester,
          (context) => showExpenseFormDialog(
            context,
            seed: ExpenseFormSeed.duplicate(_snel(), today: _today),
            types: _types,
            rate: _rate,
            today: _today,
          ),
        );

        expect(find.textContaining('137,50'), findsOneWidget);
      },
    );

    testWidgets('paysage, clavier levé : la modale ne déborde pas', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(740, 360);
      tester.view.viewInsets = const FakeViewPadding(bottom: 160);
      addTearDown(tester.view.reset);
      await _pumpHost(
        tester,
        (context) => showExpenseFormDialog(
          context,
          seed: ExpenseFormSeed.edit(_snel()),
          types: _types,
          rate: _rate,
          today: _today,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Enregistrer les modifications'), findsOneWidget);
    });
  });

  group('fiche', () {
    testWidgets('la fiche nomme l’état du circuit, et n’offre AUCUN geste de '
        'décision : décider n’est pas un clic de liste', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpHost(
        tester,
        (context) => showExpenseDetailDialog(
          context,
          expense: _snel(),
          type: _types.first,
          reader: ExpenseUsdReader(_rate),
          thread: const [],
        ),
      );

      expect(find.text('En attente'), findsOneWidget);
      expect(find.text('Marquer payée'), findsNothing);
      // Une demande non réglée ne montre pas de date de règlement (A2).
      expect(find.text('Payée le'), findsNothing);
    });

    testWidgets('payée : le badge et la date de règlement (A2)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpHost(
        tester,
        (context) => showExpenseDetailDialog(
          context,
          expense: _snel(status: ExpenseStatus.paid),
          type: _types.first,
          reader: ExpenseUsdReader(_rate),
          thread: const [],
        ),
      );

      // Deux fois « Payée » : la pastille de la tête, et le jalon de la
      // chaîne. Le mot est le même parce que l'état l'est.
      expect(find.text('Payée'), findsNWidgets(2));
      expect(find.text('Payée le'), findsOneWidget);
      // La chaîne n'attend plus rien sur une demande soldée.
      expect(find.text('en attente'), findsNothing);
    });

    testWidgets('supprimer ferme la fiche et rend le choix', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      ExpenseDetailOutcome? outcome;
      await _pumpHost(tester, (context) async {
        outcome = await showExpenseDetailDialog(
          context,
          expense: _snel(),
          type: _types.first,
          reader: ExpenseUsdReader.withoutRate,
          thread: const [],
        );
      });

      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      // Supprimer reste un RACCOURCI d'écran : il retire la ligne du
      // registre, il ne pose aucun geste du circuit.
      expect(
        outcome,
        isA<ExpenseDetailShortcut>().having(
          (o) => o.choice,
          'choice',
          ExpenseDetailChoice.withdraw,
        ),
      );
      expect(find.text('Facture SNEL'), findsNothing);
    });

    testWidgets('refusée : la fiche porte le motif du serveur (A4)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpHost(
        tester,
        (context) => showExpenseDetailDialog(
          context,
          expense: _snel(
            sync: ExpenseSyncState.rejected,
            code: 'EXPENSE_DATE_IN_FUTURE',
          ),
          type: _types.first,
          reader: ExpenseUsdReader.withoutRate,
          thread: const [],
        ),
      );

      expect(
        find.textContaining('la date de la dépense est dans le futur'),
        findsOneWidget,
      );
    });
  });

  group('fil de la demande', () {
    ExpenseMessage message(
      String id, {
      required String body,
      ExpenseAct? act,
      String? authorId = 'u-9',
      int hour = 8,
    }) => ExpenseMessage(
      id: id,
      expenseId: 'e-1',
      body: body,
      act: act,
      authorId: authorId,
      authorName: 'Mbala Thérèse',
      createdAt: DateTime.utc(2026, 9, 20, hour),
    );

    Future<void> pumpThread(
      WidgetTester tester,
      List<ExpenseMessage>? thread, {
      String? accountId,
    }) async {
      await tester.binding.setSurfaceSize(const Size(1280, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpHost(
        tester,
        (context) => showExpenseDetailDialog(
          context,
          expense: _snel(),
          type: _types.first,
          reader: ExpenseUsdReader.withoutRate,
          thread: thread,
          accountId: accountId,
        ),
      );
    }

    testWidgets('chaque geste est nommé, les messages sont comptés, et un '
        'commentaire libre ne constate rien', (tester) async {
      await pumpThread(tester, [
        message('m-1', body: 'Facture du mois', act: ExpenseAct.deposit),
        message('m-2', body: 'Accordée', act: ExpenseAct.approval, hour: 9),
        message('m-3', body: 'Payer avant vendredi', hour: 10),
      ]);

      expect(find.text('Fil de la demande'), findsOneWidget);
      expect(find.text('3 messages'), findsOneWidget);
      expect(find.text('Demande déposée'), findsOneWidget);
      expect(find.text('Approbation'), findsOneWidget);
      expect(find.text('Payer avant vendredi'), findsOneWidget);
      // Le commentaire libre n'emprunte l'étiquette d'aucun acte.
      expect(find.text('Paiement constaté'), findsNothing);
    });

    testWidgets('un fil vide annonce ce qui viendra : ce n’est pas un échec, '
        'et il ne réclame aucune action', (tester) async {
      await pumpThread(tester, const []);

      expect(find.text('aucun message'), findsOneWidget);
      expect(
        find.textContaining("chaque décision s'inscrira ici"),
        findsOneWidget,
      );
    });

    testWidgets('un fil ILLISIBLE se dit, et ne se confond pas avec un fil '
        'vide', (tester) async {
      await pumpThread(tester, null);

      expect(
        find.text("Le fil n'a pas pu être lu sur ce poste."),
        findsOneWidget,
      );
      expect(find.textContaining('chaque décision'), findsNothing);
      // Rien à compter quand rien n'a été lu.
      expect(find.text('aucun message'), findsNothing);
    });

    testWidgets('l’auteur est nommé, et la propriété se juge sur le COMPTE : '
        'un homonyme ne s’approprie pas le message', (tester) async {
      await pumpThread(tester, [
        message('m-1', body: 'Accordée', act: ExpenseAct.approval),
      ], accountId: 'u-1');

      expect(find.text('Mbala Thérèse'), findsOneWidget);
      expect(find.text('Accordée'), findsOneWidget);
    });
  });

  group('panneau de refus', () {
    const motifDevis =
        'Devis manquant : joindre au moins deux offres avant de réengager la '
        'dépense.';

    /// Rend un **lecteur**, pas une valeur : la fiche n'est pas encore fermée
    /// quand cette fonction rend la main, et renvoyer `outcome` tel quel
    /// donnerait `null` quoi qu'il arrive ensuite — une assertion toujours
    /// vraie, donc muette.
    Future<ExpenseDetailOutcome? Function()> ouvrirEtRefuser(
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      ExpenseDetailOutcome? outcome;
      await _pumpHost(tester, (context) async {
        outcome = await showExpenseDetailDialog(
          context,
          expense: _snel(),
          type: _types.first,
          reader: ExpenseUsdReader.withoutRate,
          thread: const [],
        );
      });
      await tester.tap(find.text('Refuser'));
      await tester.pumpAndSettle();
      return () => outcome;
    }

    Future<void> confirmer(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Confirmer le refus'));
      await tester.tap(find.text('Confirmer le refus'));
      await tester.pumpAndSettle();
    }

    testWidgets('Refuser ouvre le panneau sans fermer la fiche', (
      tester,
    ) async {
      await ouvrirEtRefuser(tester);

      expect(find.text('Refuser la demande'), findsOneWidget);
      // Le décideur garde sous les yeux ce qu'il refuse.
      expect(find.text('Facture SNEL'), findsOneWidget);
    });

    testWidgets('confirmer SANS motif : le geste ne part pas, et la fiche le '
        'dit', (tester) async {
      final outcome = await ouvrirEtRefuser(tester);

      await confirmer(tester);

      expect(
        find.text('Un refus sans motif laisse le demandeur sans issue.'),
        findsOneWidget,
      );
      expect(outcome(), isNull);
      expect(find.text('Facture SNEL'), findsOneWidget);

      // Ligne de contrôle : le même lecteur DOIT voir passer un refus motivé,
      // sinon le `isNull` ci-dessus ne prouverait rien.
      await tester.ensureVisible(find.text(motifDevis));
      await tester.tap(find.text(motifDevis));
      await tester.pumpAndSettle();
      await confirmer(tester);
      expect(outcome(), isNotNull);
    });

    testWidgets('un motif tout prêt remplit le champ, et le refus part avec '
        'lui', (tester) async {
      final outcome = await ouvrirEtRefuser(tester);

      await tester.ensureVisible(find.text(motifDevis));
      await tester.tap(find.text(motifDevis));
      await tester.pumpAndSettle();
      await confirmer(tester);

      expect(
        outcome(),
        isA<ExpenseDetailGesture>()
            .having((o) => o.gesture, 'gesture', ExpenseGesture.refuse)
            .having((o) => o.note, 'note', motifDevis),
      );
    });

    testWidgets('annuler referme le panneau et laisse la demande intacte', (
      tester,
    ) async {
      final outcome = await ouvrirEtRefuser(tester);

      await tester.ensureVisible(find.text('Annuler'));
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(find.text('Refuser la demande'), findsNothing);
      expect(outcome(), isNull);
      expect(find.text('Refuser'), findsOneWidget);
    });
  });
}
