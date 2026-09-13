import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_local_model.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_read_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_write_dao.dart';
import 'package:school_app_flutter/features/expense/data/mappers/expense_mappers.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

const _sent = '2026-09-03T09:00:00.000Z';
const _later = '2026-09-03T09:05:00.000Z';

ExpenseLocalModel _model({
  String? number,
  String syncStatus = 'PENDING_SYNC',
  String title = 'Facture SNEL',
}) => ExpenseLocalModel(
  id: 'e-1',
  schoolId: 'school-1',
  expenseNumber: number,
  typeId: 't-elec',
  title: title,
  amountInCents: 500,
  currency: 'USD',
  status: 'PAID',
  expenseDate: '2026-09-03',
  clientUpdatedAt: _sent,
  syncStatus: syncStatus,
);

ExpenseSyncRequestDto _request(ExpenseLocalModel row) =>
    ExpenseSyncRequestDto(expense: row.toInput(), authorId: 'u-1');

void main() {
  late Database db;
  late ExpenseWriteDao dao;
  late ExpenseReadDao reader;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = ExpenseWriteDao(db);
    reader = ExpenseReadDao(db);
  });
  tearDown(() async => db.close());

  Future<ExpenseLocalModel> row() async => (await reader.find('e-1'))!;

  Future<List<Object?>> outboxStatuses() async => [
    for (final entry in await db.query('outbox', orderBy: 'id'))
      entry['status'],
  ];

  test('une saisie ne défait jamais ce qu’un accusé a posé entre la lecture '
      'de la ligne et son écriture', () async {
    // La base porte l'accusé : numéro, version, retrait vu du serveur.
    await db.insert(
      'expenses',
      _model(number: 'DEP-0412', syncStatus: 'SYNCED').toMap()
        ..['version'] = 3
        ..['server_deleted_at'] = _sent,
    );
    // La saisie a été construite depuis une lecture d'AVANT l'accusé.
    final stale = _model(title: 'Facture SNEL corrigée');

    await dao.saveExpense(row: stale, request: _request(stale), nowMs: 1);

    final r = await row();
    expect(r.title, 'Facture SNEL corrigée');
    expect(r.syncStatus, 'PENDING_SYNC');
    expect(r.expenseNumber, 'DEP-0412');
    expect(r.version, 3);
    expect(r.serverDeletedAt, _sent);
  });

  group('setLocalOnlyWithdrawal', () {
    test('neutralise le contenu ET le retrait, quel que soit leur statut — un '
        'contenu remis en file ressusciterait la dépense', () async {
      // Refusée, puis remise en file depuis la feuille des erreurs : l'entrée
      // est PENDING, la ligne toujours « à corriger ».
      final rejected = _model(syncStatus: 'SYNC_ERROR');
      await dao.saveExpense(
        row: rejected,
        request: _request(rejected),
        nowMs: 1,
      );
      await dao.setWithdrawal(
        payload: const ExpenseWithdrawalPayload(
          expenseId: 'e-1',
          deleted: true,
          changedAt: _sent,
          authorId: 'u-1',
        ),
        schoolId: 'school-1',
        nowMs: 2,
      );

      final settled = await dao.setLocalOnlyWithdrawal(
        expenseId: 'e-1',
        deletedAt: _sent,
        nowMs: 3,
      );

      expect(settled, isTrue);
      expect(await outboxStatuses(), ['ACKED', 'ACKED']);
      final r = await row();
      expect(r.deletedAt, _sent);
      expect(r.withdrawalPendingAt, isNull);
    });

    test('accusée entre-temps : rien n’est écrit, la file décidera', () async {
      await db.insert(
        'expenses',
        _model(number: 'DEP-0412', syncStatus: 'SYNCED').toMap(),
      );

      final settled = await dao.setLocalOnlyWithdrawal(
        expenseId: 'e-1',
        deletedAt: _sent,
        nowMs: 1,
      );

      expect(settled, isFalse);
      expect((await row()).deletedAt, isNull);
    });

    test('un geste remplacé n’est pas réglé à la place du suivant', () async {
      await db.insert(
        'expenses',
        _model(syncStatus: 'SYNC_ERROR').toMap()
          ..['withdrawal_pending_at'] = _later,
      );

      final settled = await dao.setLocalOnlyWithdrawal(
        expenseId: 'e-1',
        deletedAt: _sent,
        nowMs: 1,
        expectedPendingAt: _sent,
      );

      expect(settled, isFalse);
      expect((await row()).withdrawalPendingAt, _later);
    });
  });
}
