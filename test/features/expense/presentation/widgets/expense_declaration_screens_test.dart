import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_voucher.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_voucher_image.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_queue_sort.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_register_query.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_declaration_support.dart';
import 'package:school_app_flutter/features/expense/presentation/projections/expense_queue_view.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_status_badge.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_detail_dialog.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_reason_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQ'
  'DwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

Expense _declared({
  String id = 'e-1',
  ExpenseStatus status = ExpenseStatus.paid,
  ExpenseVisaStatus? visa = ExpenseVisaStatus.pending,
  ExpenseSyncState sync = ExpenseSyncState.synced,
  String? number = 'DEP-0142',
  String? flagReason,
  DateTime? disbursedAt,
  DateTime? receivedAt,
}) => Expense(
  id: id,
  number: number,
  typeId: 't-fuel',
  title: 'Carburant groupe',
  amountInCents: 4500,
  currency: 'USD',
  status: status,
  paidOn: DateTime(2026, 11, 25),
  expenseDate: DateTime(2026, 11, 25),
  clientUpdatedAt: DateTime.utc(2026, 11, 25),
  mode: ExpenseMode.declaration,
  visaStatus: visa,
  flagReason: flagReason,
  syncState: sync,
  disbursedAt: disbursedAt ?? DateTime.utc(2026, 11, 25, 9, 12),
  voucher: receivedAt == null
      ? null
      : ExpenseVoucher(
          id: 'v-$id',
          contentType: 'image/png',
          sizeBytes: 70,
          uploadedAt: receivedAt,
        ),
);

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('fr'),
  home: Scaffold(body: Center(child: child)),
);

/// DEP-21 — la déclaration dans le registre, la file et la fiche.
void main() {
  group('pastilles', () {
    testWidgets('à viser, annulée, à régulariser', (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              ExpenseVisaBadge(expense: _declared()),
              ExpenseStatusBadge.of(
                _declared(status: ExpenseStatus.retracted, visa: null),
              ),
              ExpenseSyncBadge(
                expense: _declared(
                  number: null,
                  sync: ExpenseSyncState.rejected,
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('À viser'), findsOneWidget);
      expect(find.text('Annulée'), findsOneWidget);
      expect(find.text('Retirée'), findsNothing);
      expect(find.text('À régulariser'), findsOneWidget);
    });
  });

  test('le filtre de visa ne garde que des déclarations', () {
    final authorization = Expense(
      id: 'a-1',
      typeId: 't-fuel',
      title: 'Demande',
      amountInCents: 100,
      currency: 'USD',
      status: ExpenseStatus.pending,
      expenseDate: DateTime(2026, 11, 25),
      clientUpdatedAt: DateTime.utc(2026, 11, 25),
    );
    final rows = [
      authorization,
      _declared(id: 'd-1'),
      _declared(id: 'd-2', visa: ExpenseVisaStatus.visaed),
    ];

    final kept = ExpenseRegisterQuery.apply(
      rows,
      const ExpenseQuery(visa: ExpenseVisaStatus.pending),
      const {},
    );

    expect(kept.map((e) => e.id), ['d-1']);
  });

  test('la file « À viser » : signalées comprises, plus ancienne en tête', () {
    final view = ExpenseQueueView.compute(
      snapshot: ExpenseRegisterSnapshot(
        expenses: [
          _declared(id: 'récente', disbursedAt: DateTime.utc(2026, 11, 25)),
          _declared(
            id: 'ancienne',
            visa: ExpenseVisaStatus.flagged,
            disbursedAt: DateTime.utc(2026, 11, 20),
          ),
          _declared(id: 'visée', visa: ExpenseVisaStatus.visaed),
          _declared(id: 'annulée', status: ExpenseStatus.retracted, visa: null),
        ],
        types: const [],
      ),
      sort: ExpenseQueueSort.values.first,
      today: DateTime(2026, 11, 26),
    );

    expect(view.toVisa.map((e) => e.id), ['ancienne', 'récente']);
    expect(view.pending, isEmpty, reason: 'une déclaration est déjà payée');
  });

  group('la fiche d’une déclaration', () {
    /// Ouvre la fiche ; les issues rendues s'écrivent dans [outcomes].
    Future<void> Function() open(
      WidgetTester tester,
      Expense expense, {
      ExpenseVoucherImage? image,
      bool canCancel = true,
      bool canRedeclare = false,
      List<ExpenseDetailOutcome?>? outcomes,
    }) {
      return () async {
        await tester.binding.setSurfaceSize(const Size(1280, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          _app(
            Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  final outcome = await showExpenseDetailDialog(
                    context,
                    expense: expense,
                    type: null,
                    reader: ExpenseUsdReader.withoutRate,
                    thread: const [],
                    accountId: 'u-prom',
                    allowShortcuts: true,
                    declaration: ExpenseDeclarationSupport(
                      loadVoucher: (_) async => Right(image),
                      canCancel: (_) async => canCancel,
                      canRedeclare: canRedeclare,
                    ),
                  );
                  outcomes?.add(outcome);
                },
                child: const Text('ouvrir'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('ouvrir'));
        await tester.pumpAndSettle();
      };
    }

    testWidgets('photo chargée : Viser actif, et rend le geste', (
      tester,
    ) async {
      final outcomes = <ExpenseDetailOutcome?>[];
      await open(
        tester,
        _declared(),
        image: ExpenseVoucherImage(bytes: _png, contentType: 'image/png'),
        outcomes: outcomes,
      )();

      expect(find.text('Annuler la déclaration'), findsOneWidget);
      await tester.tap(find.text('Viser'));
      await tester.pumpAndSettle();

      final outcome = outcomes.single! as ExpenseDetailGesture;
      expect(outcome.gesture, ExpenseGesture.visa);
    });

    testWidgets('sans photo : Viser reste fermé', (tester) async {
      await open(tester, _declared())();

      expect(find.text('Pas de photo du bon'), findsOneWidget);
      await tester.tap(find.text('Viser'));
      await tester.pumpAndSettle();
      expect(
        find.text('Viser'),
        findsOneWidget,
        reason: 'désactivé : la fiche reste ouverte',
      );
    });

    testWidgets('journée close : Annuler caché, et la fiche dit pourquoi', (
      tester,
    ) async {
      await open(
        tester,
        _declared(),
        image: ExpenseVoucherImage(bytes: _png, contentType: 'image/png'),
        canCancel: false,
      )();

      expect(find.text('Annuler la déclaration'), findsNothing);
      expect(find.textContaining('ajustement de caisse'), findsOneWidget);
    });

    testWidgets('signaler ouvre le motif, obligatoire', (tester) async {
      await open(
        tester,
        _declared(),
        image: ExpenseVoucherImage(bytes: _png, contentType: 'image/png'),
      )();

      await tester.tap(find.text('Signaler'));
      await tester.pumpAndSettle();
      expect(find.text('Signaler cette déclaration'), findsOneWidget);
      expect(find.byType(ExpenseReasonDialog), findsOneWidget);
      // La modale est au-dessus : son bouton est le dernier de l'arbre.
      await tester.tap(find.text('Signaler').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Le motif est obligatoire pour signaler.'),
        findsOneWidget,
      );
    });

    testWidgets('signaler : le motif saisi rend le geste, fiche fermée', (
      tester,
    ) async {
      final outcomes = <ExpenseDetailOutcome?>[];
      await open(
        tester,
        _declared(),
        image: ExpenseVoucherImage(bytes: _png, contentType: 'image/png'),
        outcomes: outcomes,
      )();

      await tester.tap(find.text('Signaler'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bon illisible ou incomplet'));
      await tester.pump();
      await tester.tap(find.text('Signaler').last);
      await tester.pumpAndSettle();

      final outcome = outcomes.single! as ExpenseDetailGesture;
      expect(outcome.gesture, ExpenseGesture.flag);
      expect(outcome.note, 'Bon illisible ou incomplet');
      expect(find.byType(ExpenseReasonDialog), findsNothing);
    });

    testWidgets('signaler puis renoncer : la fiche reste, rien ne part', (
      tester,
    ) async {
      final outcomes = <ExpenseDetailOutcome?>[];
      await open(
        tester,
        _declared(),
        image: ExpenseVoucherImage(bytes: _png, contentType: 'image/png'),
        outcomes: outcomes,
      )();

      await tester.tap(find.text('Signaler'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler').last);
      await tester.pumpAndSettle();

      expect(find.byType(ExpenseReasonDialog), findsNothing);
      expect(find.text('Viser'), findsOneWidget);
      expect(outcomes, isEmpty);
    });

    testWidgets('signaler sur téléphone, texte ×1,3 : rien ne déborde', (
      tester,
    ) async {
      await open(
        tester,
        _declared(),
        image: ExpenseVoucherImage(bytes: _png, contentType: 'image/png'),
      )();
      await tester.binding.setSurfaceSize(const Size(360, 740));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Signaler'));
      await tester.pumpAndSettle();

      expect(find.byType(ExpenseReasonDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('refusée par le serveur : Redéclarer, pas Dupliquer', (
      tester,
    ) async {
      await open(
        tester,
        _declared(number: null, sync: ExpenseSyncState.rejected),
        image: ExpenseVoucherImage(bytes: _png, contentType: 'image/png'),
        canRedeclare: true,
      )();

      expect(find.text('Redéclarer'), findsOneWidget);
      expect(find.text('Dupliquer'), findsNothing);
      expect(
        find.text('Supprimer'),
        findsNothing,
        reason: 'l’argent est sorti',
      );
      expect(find.text('Viser'), findsNothing, reason: 'inconnue du serveur');
      expect(find.textContaining('Redéclarez-la'), findsOneWidget);
    });

    testWidgets('déclarée tard : la fiche le dit au promoteur', (tester) async {
      await open(
        tester,
        _declared(
          disbursedAt: DateTime.utc(2026, 11, 20, 9),
          receivedAt: DateTime.utc(2026, 11, 24, 10),
        ),
        image: ExpenseVoucherImage(bytes: _png, contentType: 'image/png'),
      )();

      expect(
        find.text('Déclarée 4 jours après le décaissement'),
        findsOneWidget,
      );
    });

    testWidgets('déclarée le jour même : aucune mention', (tester) async {
      await open(
        tester,
        _declared(receivedAt: DateTime.utc(2026, 11, 25, 9, 13)),
        image: ExpenseVoucherImage(bytes: _png, contentType: 'image/png'),
      )();

      expect(find.textContaining('après le décaissement'), findsNothing);
    });

    testWidgets('signalée : le motif se lit dans la fiche', (tester) async {
      await open(
        tester,
        _declared(
          visa: ExpenseVisaStatus.flagged,
          flagReason: 'Montant supérieur au devis',
        ),
        image: ExpenseVoucherImage(bytes: _png, contentType: 'image/png'),
      )();

      expect(
        find.text('Signalée : Montant supérieur au devis'),
        findsOneWidget,
      );
      expect(find.text('Signaler'), findsNothing, reason: 'déjà signalée');
    });
  });
}
