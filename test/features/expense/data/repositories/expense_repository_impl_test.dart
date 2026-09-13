import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/expense/local/expense_type_local_model.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/exchange_rate_reader.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_read_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_type_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_write_dao.dart';
import 'package:school_app_flutter/features/expense/data/repositories/expense_repository_impl.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

class _Ids implements IdGenerator {
  @override
  String newId() => 'e-new';
}

class _MockEngine extends Mock implements SyncEngine {}

class _Rates implements ExchangeRateReader {
  final List<ExchangeRate> rates;
  const _Rates(this.rates);
  @override
  Future<List<ExchangeRate>> forCurrentSchool() async => rates;
}

// Samedi 12 septembre 2026, 15 h.
final _now = DateTime(2026, 9, 12, 15);

ExpenseDraft _draft({
  String? id,
  ExpenseStatus status = ExpenseStatus.paid,
  DateTime? day,
}) => ExpenseDraft(
  id: id,
  typeId: 't-elec',
  title: '  Facture SNEL  ',
  description: '   ',
  amountInCents: 38500000,
  currency: 'cdf',
  status: status,
  expenseDate: day ?? DateTime(2026, 9, 3, 18, 30),
  supplier: 'SNEL',
  recordedByName: 'Moke Junior',
);

void main() {
  late Database db;
  late ExpenseRepositoryImpl repo;
  late CurrentUserContext user;

  ExpenseRepositoryImpl build({SyncEngine? engine}) => ExpenseRepositoryImpl(
    reader: ExpenseReadDao(db),
    writer: ExpenseWriteDao(db),
    types: ExpenseTypeDao(db),
    currentUser: user,
    ids: _Ids(),
    rates: _Rates([
      ExchangeRate(
        base: 'USD',
        quote: 'CDF',
        rateMicros: 2800 * ExchangeRate.scale,
        effectiveFrom: DateTime.utc(2026, 9, 1),
      ),
    ]),
    schoolYearStart: () async => DateTime(2025, 9, 7),
    syncEngine: engine,
    now: () => _now,
  );

  setUp(() async {
    db = await openFullOfflineDb();
    user = CurrentUserContext()..set('u-1', schoolId: 'school-1');
    repo = build();
  });
  tearDown(() async => db.close());

  Future<List<Map<String, Object?>>> outbox() =>
      db.query('outbox', orderBy: 'created_at');

  Future<Expense> saved(ExpenseDraft draft) async =>
      (await repo.save(draft)).fold((f) => fail('$f'), (e) => e);

  group('save', () {
    test('création payée : ligne en attente, date de règlement = date de la '
        'dépense (A2), et UNE entrée d’outbox portant l’auteur', () async {
      final expense = await saved(_draft());

      expect(expense.id, 'e-new');
      expect(expense.title, 'Facture SNEL');
      expect(expense.description, isNull);
      expect(expense.currency, 'CDF');
      expect(expense.paidOn, DateTime(2026, 9, 3));
      expect(expense.syncState, ExpenseSyncState.pending);
      expect(expense.number, isNull, reason: 'A3 : numéro en attente');

      final entries = await outbox();
      expect(entries, hasLength(1));
      expect(entries.single['id'], 'EXPENSE:e-new');
      final payload = jsonDecode(entries.single['payload'] as String) as Map;
      expect(payload['authorId'], 'u-1');
      expect(payload['expense']['expenseDate'], '2026-09-03');
      expect(payload['expense']['paidOn'], '2026-09-03');
      expect(payload['expense']['amountInCents'], 38500000);
    });

    test(
      'bascule en payée : réglée AUJOURD’HUI ; en non payée : sans date',
      () async {
        final created = await saved(_draft(status: ExpenseStatus.unpaid));
        expect(created.paidOn, isNull);

        final paid = (await repo.setStatus(
          created,
          ExpenseStatus.paid,
        )).fold((f) => fail('$f'), (e) => e);
        expect(paid.paidOn, DateTime(2026, 9, 12));

        // Une modification qui la laisse payée garde sa date de règlement.
        final edited = await saved(_draft(id: paid.id));
        expect(edited.paidOn, DateTime(2026, 9, 12));

        final unpaid = (await repo.setStatus(
          edited,
          ExpenseStatus.unpaid,
        )).fold((f) => fail('$f'), (e) => e);
        expect(unpaid.paidOn, isNull);
        // Toujours une seule entrée : chaque geste remplace le précédent.
        expect(await outbox(), hasLength(1));
      },
    );

    test('sans école : refus local, rien d’écrit', () async {
      user.clear();
      expect((await repo.save(_draft())).isLeft(), isTrue);
      expect(await outbox(), isEmpty);
    });

    test('sans agent connecté : refus local — une entrée sans auteur serait '
        'refusée, donc perdue', () async {
      final expense = await saved(_draft());
      user.set(null, schoolId: 'school-1');

      expect((await repo.save(_draft())).isLeft(), isTrue);
      expect((await repo.withdraw(expense)).isLeft(), isTrue);
      expect(await outbox(), hasLength(1), reason: 'la seule création d’avant');
    });

    test('chaque écriture pousse sans attendre le battement', () async {
      final engine = _MockEngine();
      when(
        () => engine.flush(),
      ).thenAnswer((_) async => const SyncFlushReport.skipped());
      final pushing = build(engine: engine);

      final expense = (await pushing.save(
        _draft(),
      )).fold((f) => fail('$f'), (e) => e);
      await db.update('expenses', {'expense_number': 'DEP-1'});
      await pushing.withdraw(expense);

      verify(() => engine.flush()).called(2);
    });
  });

  group('retrait', () {
    test('dépense connue du serveur : retrait local + geste en file', () async {
      final expense = await saved(_draft());
      await db.update('expenses', {'expense_number': 'DEP-1'});

      await repo.withdraw(expense);

      final row = (await ExpenseReadDao(db).find('e-new'))!;
      expect(row.deletedAt, isNotNull);
      expect(row.withdrawalPendingAt, row.deletedAt);
      final withdrawal = (await outbox()).firstWhere(
        (e) => e['aggregate_type'] == 'EXPENSE_WITHDRAWAL',
      );
      expect(jsonDecode(withdrawal['payload'] as String)['deleted'], isTrue);
    });

    test('jamais acceptée : retrait sur le poste seul, l’envoi refusé est '
        'neutralisé — rien n’attendra un numéro qui ne viendra pas', () async {
      final expense = await saved(_draft());
      await db.update('expenses', {'sync_status': 'SYNC_ERROR'});
      await db.update('outbox', {'status': 'SYNC_ERROR'});

      await repo.withdraw(expense);

      final entries = await outbox();
      expect(entries.map((e) => e['aggregate_type']), ['EXPENSE']);
      expect(entries.single['status'], 'ACKED');
      expect((await ExpenseReadDao(db).find('e-new'))!.deletedAt, isNotNull);

      await repo.restore(expense);
      expect((await ExpenseReadDao(db).find('e-new'))!.deletedAt, isNull);
      expect(
        await outbox(),
        hasLength(1),
        reason: 'restaurer ne remet rien en file',
      );
    });
  });

  test('loadRegister : types, registre, taux du jour et rentrée', () async {
    await ExpenseTypeDao(db).replaceForSchool([
      const ExpenseTypeLocalModel(
        id: 't-elec',
        schoolId: 'school-1',
        code: 'ELECTRICITE',
        label: 'Électricité & eau',
        shortLabel: '',
        icon: 'power',
        color: '#D9A24E',
        softColor: '#FBF3E3',
        defaultCurrency: 'CDF',
      ),
    ], schoolId: 'school-1');
    await saved(_draft());

    final snapshot = (await repo.loadRegister()).fold(
      (f) => fail('$f'),
      (s) => s,
    );

    expect(snapshot.types.single.shortLabel, 'Électricité & eau');
    expect(snapshot.expenses.single.id, 'e-new');
    expect(snapshot.usdToCdf?.rateMicros, 2800 * ExchangeRate.scale);
    expect(snapshot.anchor.month, 9);
    expect(snapshot.anchor.day, 7);
  });
}
