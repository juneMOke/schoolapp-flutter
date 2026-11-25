import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/money/cash_closure_reader.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_gesture_columns.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_gesture_payload.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_declaration_cancellation.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_gesture_policy.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_gesture_access.dart';
import 'package:school_app_flutter/features/treasury/data/local/treasury_closure_dao.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

class _Closures implements CashClosureReader {
  final bool closed;
  final bool throws;
  _Closures({this.closed = false, this.throws = false});

  DateTime? askedDay;
  String? askedCurrency;

  @override
  Future<bool> hasLiveClosureFrom(DateTime day, String currency) async {
    if (throws) throw StateError('disque');
    askedDay = day;
    askedCurrency = currency;
    return closed;
  }
}

/// DEP-19 — viser, signaler, annuler une déclaration.
void main() {
  Expense declared({
    ExpenseStatus status = ExpenseStatus.paid,
    ExpenseVisaStatus? visa = ExpenseVisaStatus.pending,
    ExpenseFundingSource funding = ExpenseFundingSource.cash,
    DateTime? cashDay,
    bool afterClosure = false,
    ExpenseMode mode = ExpenseMode.declaration,
  }) => Expense(
    id: 'e-1',
    typeId: 't-1',
    title: 'Carburant',
    amountInCents: 4500,
    currency: 'USD',
    status: status,
    expenseDate: DateTime(2026, 11, 25),
    clientUpdatedAt: DateTime.utc(2026, 11, 25),
    fundingSource: funding,
    mode: mode,
    visaStatus: visa,
    cashDay: cashDay,
    afterClosure: afterClosure,
  );

  Set<ExpenseGesture> offered(Expense e) =>
      ExpenseGesturePolicy.offeredOn(e, accountId: 'u-1').toSet();

  group('les gestes offerts', () {
    test('à viser : viser, signaler, annuler, commenter', () {
      expect(offered(declared()), {
        ExpenseGesture.comment,
        ExpenseGesture.reopen,
        ExpenseGesture.visa,
        ExpenseGesture.flag,
      });
    });

    test('signalée : visable, pas resignalable', () {
      final gestures = offered(declared(visa: ExpenseVisaStatus.flagged));
      expect(gestures, contains(ExpenseGesture.visa));
      expect(gestures, isNot(contains(ExpenseGesture.flag)));
    });

    test('visée : terminal pour le visa', () {
      final gestures = offered(declared(visa: ExpenseVisaStatus.visaed));
      expect(gestures, isNot(contains(ExpenseGesture.visa)));
      expect(gestures, isNot(contains(ExpenseGesture.flag)));
    });

    test('annulée : ni visa ni signalement', () {
      expect(offered(declared(status: ExpenseStatus.retracted, visa: null)), {
        ExpenseGesture.comment,
      });
    });

    test(
      'refusée par le serveur : seulement commenter (elle n’y existe pas)',
      () {
        final refused = Expense(
          id: 'e-1',
          typeId: 't-1',
          title: 'Carburant',
          amountInCents: 4500,
          currency: 'USD',
          status: ExpenseStatus.paid,
          expenseDate: DateTime(2026, 11, 25),
          clientUpdatedAt: DateTime.utc(2026, 11, 25),
          mode: ExpenseMode.declaration,
          visaStatus: ExpenseVisaStatus.pending,
          syncState: ExpenseSyncState.rejected,
        );
        expect(offered(refused), {ExpenseGesture.comment});
      },
    );

    test('jamais sur une demande d’autorisation', () {
      for (final status in ExpenseStatus.values) {
        final gestures = offered(
          declared(status: status, mode: ExpenseMode.authorization, visa: null),
        );
        expect(gestures, isNot(contains(ExpenseGesture.visa)));
        expect(gestures, isNot(contains(ExpenseGesture.flag)));
      }
    });

    test('viser et signaler sous expense.decide, sur leurs routes', () {
      expect(expenseGestureAccess(ExpenseGesture.visa), kExpenseDecideAccess);
      expect(expenseGestureAccess(ExpenseGesture.flag), kExpenseDecideAccess);
      ExpenseGesturePayload payload(ExpenseGesture g) => ExpenseGesturePayload(
        expenseId: 'e-1',
        gesture: g,
        messageId: 'm-1',
        body: '',
        decidedAt: '2026-11-26T07:40:00.000Z',
      );
      expect(payload(ExpenseGesture.visa).endpoint, endsWith('/visa'));
      expect(payload(ExpenseGesture.flag).endpoint, endsWith('/flag'));
      expect(ExpenseGesture.flag.requiresNote, isTrue);
      expect(ExpenseGesture.visa.requiresNote, isFalse);
    });
  });

  group('ce que le geste écrit sur la ligne', () {
    final at = DateTime.utc(2026, 11, 26, 7, 40);

    test('viser : le visa et son auteur, motif levé', () {
      final columns = ExpenseGestureColumns.of(
        ExpenseGesture.visa,
        actorId: 'u-prom',
        actorName: 'Le promoteur',
        at: at,
        reason: 'ok',
        mode: ExpenseMode.declaration,
      );
      expect(columns, {
        'visa_status': 'VISAED',
        'visa_by_id': 'u-prom',
        'visa_by_name': 'Le promoteur',
        'visa_at': '2026-11-26T07:40:00.000Z',
        'flag_reason': null,
      });
      expect(columns.containsKey('status'), isFalse);
    });

    test('signaler : le motif reste', () {
      final columns = ExpenseGestureColumns.of(
        ExpenseGesture.flag,
        actorId: 'u-prom',
        actorName: 'Le promoteur',
        at: at,
        reason: 'Montant supérieur au devis',
        mode: ExpenseMode.declaration,
      );
      expect(columns['visa_status'], 'FLAGGED');
      expect(columns['flag_reason'], 'Montant supérieur au devis');
    });

    test('annuler une déclaration : RETRACTED, visa effacé', () {
      final columns = ExpenseGestureColumns.of(
        ExpenseGesture.reopen,
        actorId: 'u-prom',
        actorName: null,
        at: at,
        mode: ExpenseMode.declaration,
      );
      expect(columns['status'], 'RETRACTED');
      expect(columns['visa_status'], isNull);
      expect(columns.containsKey('visa_status'), isTrue);
    });

    test('rouvrir une demande d’autorisation ne change pas', () {
      final columns = ExpenseGestureColumns.of(
        ExpenseGesture.reopen,
        actorId: 'u-prom',
        actorName: null,
        at: at,
      );
      expect(columns['status'], 'PENDING');
      expect(columns.containsKey('visa_status'), isFalse);
    });
  });

  group('« Annuler » et la journée de caisse (F44)', () {
    test('ouverte : annulable, la journée de la sortie est lue', () async {
      final reader = _Closures();
      final rule = ExpenseDeclarationCancellation(reader);

      expect(
        await rule.canCancel(declared(cashDay: DateTime(2026, 11, 26))),
        isTrue,
      );
      expect(reader.askedDay, DateTime(2026, 11, 26));
      expect(reader.askedCurrency, 'USD');
    });

    test('close à cette journée ou après : caché', () async {
      final rule = ExpenseDeclarationCancellation(_Closures(closed: true));
      expect(
        await rule.canCancel(declared(cashDay: DateTime(2026, 11, 26))),
        isFalse,
      );
    });

    test('après clôture : caché, réponse ou pas (Q6)', () async {
      final rule = ExpenseDeclarationCancellation(_Closures());
      expect(
        await rule.canCancel(
          declared(cashDay: DateTime(2026, 11, 26), afterClosure: true),
        ),
        isFalse,
      );
    });

    test('hors espèces : aucune caisse, annulable', () async {
      final rule = ExpenseDeclarationCancellation(_Closures(closed: true));
      expect(
        await rule.canCancel(declared(funding: ExpenseFundingSource.bank)),
        isTrue,
      );
    });

    test('une lecture ratée cache le geste', () async {
      final rule = ExpenseDeclarationCancellation(_Closures(throws: true));
      expect(
        await rule.canCancel(declared(cashDay: DateTime(2026, 11, 26))),
        isFalse,
      );
    });

    test('déjà annulée : non', () async {
      final rule = ExpenseDeclarationCancellation(_Closures());
      expect(
        await rule.canCancel(declared(status: ExpenseStatus.retracted)),
        isFalse,
      );
    });
  });

  group('les clôtures vivantes, sur la tablette', () {
    late Database db;
    late TreasuryClosureDao dao;

    setUp(() async {
      db = await openFullOfflineDb();
      dao = TreasuryClosureDao(
        db,
        CurrentUserContext()..set('u-1', schoolId: 'school-1'),
      );
      Future<void> closure(String id, String day, {String? reopenedAt}) =>
          db.insert('treasury_closures', {
            'id': id,
            'school_id': 'school-1',
            'register_id': 'r-usd',
            'currency': 'USD',
            'cash_day': day,
            'closed_at': '${day}T18:00:00Z',
            'reopened_at': reopenedAt,
            'synced_at': 0,
          });
      await closure('c-1', '2026-11-24');
      await closure('c-2', '2026-11-27', reopenedAt: '2026-11-27T19:00:00Z');
    });
    tearDown(() => db.close());

    test(
      'une clôture à la journée ou après fige ; une rouverte, non',
      () async {
        expect(
          await dao.hasLiveClosureFrom(DateTime(2026, 11, 24), 'usd'),
          true,
        );
        expect(
          await dao.hasLiveClosureFrom(DateTime(2026, 11, 20), 'USD'),
          true,
        );
        expect(
          await dao.hasLiveClosureFrom(DateTime(2026, 11, 25), 'USD'),
          isFalse,
          reason: 'la seule clôture postérieure a été rouverte',
        );
        expect(
          await dao.hasLiveClosureFrom(DateTime(2026, 11, 20), 'CDF'),
          false,
        );
      },
    );
  });
}
