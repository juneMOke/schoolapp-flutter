import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_local_model.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_read_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_sync_dao.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_delta_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

const _sent = '2026-09-03T09:00:00.000Z';
const _later = '2026-09-03T09:05:00.000Z';

ExpenseDeltaDto _canonical({
  String clientUpdatedAt = _sent,
  String title = 'Version serveur',
  String? deletedAt,
}) => ExpenseDeltaDto(
  id: 'e-1',
  expenseNumber: 'DEP-0412',
  typeId: 't-elec',
  title: title,
  amountInCents: 500,
  currency: 'USD',
  status: 'PAID',
  expenseDate: '2026-09-03',
  recordedByName: 'Moke Junior',
  clientUpdatedAt: clientUpdatedAt,
  deletedAt: deletedAt,
  version: 1,
  serverUpdatedAt: '2026-09-03T09:14:02Z',
);

void main() {
  late Database db;
  late ExpenseSyncDao dao;
  late ExpenseReadDao reader;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = ExpenseSyncDao(db);
    reader = ExpenseReadDao(db);
  });
  tearDown(() async => db.close());

  Future<void> seed({
    String syncStatus = 'PENDING_SYNC',
    String clientUpdatedAt = _sent,
    String? withdrawalPendingAt,
    String? deletedAt,
    String? serverDeletedAt,
    String? number,
  }) => db.insert(
    'expenses',
    ExpenseLocalModel(
      id: 'e-1',
      schoolId: 'school-1',
      expenseNumber: number,
      typeId: 't-elec',
      title: 'Version locale',
      amountInCents: 900,
      currency: 'USD',
      status: 'UNPAID',
      expenseDate: '2026-09-03',
      clientUpdatedAt: clientUpdatedAt,
      deletedAt: deletedAt,
      serverDeletedAt: serverDeletedAt,
      withdrawalPendingAt: withdrawalPendingAt,
      syncStatus: syncStatus,
    ).toMap(),
  );

  Future<ExpenseLocalModel> row() async => (await reader.find('e-1'))!;

  group('applyContentAck', () {
    test(
      'état envoyé = état local : la ligne s’aligne et passe SYNCED',
      () async {
        await seed();
        await dao.applyContentAck(
          _canonical(),
          sentClientUpdatedAt: _sent,
          schoolId: 'school-1',
          nowMs: 1,
        );
        final r = await row();
        expect(r.syncStatus, 'SYNCED');
        expect(r.title, 'Version serveur');
        expect(r.expenseNumber, 'DEP-0412');
        expect(r.recordedByName, 'Moke Junior');
      },
    );

    test('même instant écrit autrement (…Z / ….000Z) : reconnu', () async {
      await seed(clientUpdatedAt: '2026-09-03T09:00:00Z');
      await dao.applyContentAck(
        _canonical(),
        sentClientUpdatedAt: _sent,
        schoolId: 'school-1',
        nowMs: 1,
      );
      expect((await row()).syncStatus, 'SYNCED');
    });

    test(
      'une saisie plus récente attend : contenu gardé, numéro posé',
      () async {
        await seed(clientUpdatedAt: _later);
        await dao.applyContentAck(
          _canonical(),
          sentClientUpdatedAt: _sent,
          schoolId: 'school-1',
          nowMs: 1,
        );
        final r = await row();
        expect(r.title, 'Version locale');
        expect(r.syncStatus, 'PENDING_SYNC');
        expect(r.expenseNumber, 'DEP-0412', reason: 'A3 : le numéro arrive');
      },
    );

    test(
      'un retrait en attente n’est jamais défait par l’accusé du contenu',
      () async {
        await seed(withdrawalPendingAt: _later, deletedAt: _later);
        await dao.applyContentAck(
          _canonical(),
          sentClientUpdatedAt: _sent,
          schoolId: 'school-1',
          nowMs: 1,
        );
        expect((await row()).deletedAt, _later);
      },
    );

    test('retirée sur le poste seul pendant le vol : l’accusé ne la ressuscite '
        'pas, et le retrait part à son tour', () async {
      // Jamais acceptée jusque-là, retirée en local (sans marque d'attente).
      await seed(deletedAt: _later);

      await dao.applyContentAck(
        _canonical(),
        sentClientUpdatedAt: _sent,
        schoolId: 'school-1',
        nowMs: 1,
        authorId: 'u-1',
      );

      final r = await row();
      expect(r.deletedAt, _later);
      expect(r.withdrawalPendingAt, _later);
      expect(r.expenseNumber, 'DEP-0412');
      final entries = await db.query('outbox');
      expect(entries.single['id'], 'EXPENSE_WITHDRAWAL:e-1');
      expect(jsonDecode(entries.single['payload'] as String), {
        'expenseId': 'e-1',
        'deleted': true,
        'changedAt': _later,
        'authorId': 'u-1',
      });
    });

    test('ligne effacée entre-temps : l’état canonique est inséré', () async {
      await dao.applyContentAck(
        _canonical(),
        sentClientUpdatedAt: _sent,
        schoolId: 'school-1',
        nowMs: 1,
      );
      expect((await row()).syncStatus, 'SYNCED');
    });
  });

  group('applyPulled', () {
    test('inconnue → insérée ; synchronisée → remplacée', () async {
      expect(
        await dao.applyPulled([_canonical()], schoolId: 'school-1', nowMs: 1),
        1,
      );
      expect((await row()).schoolId, 'school-1');

      await dao.applyPulled(
        [_canonical(title: 'Modifiée ailleurs')],
        schoolId: 'school-1',
        nowMs: 2,
      );
      expect((await row()).title, 'Modifiée ailleurs');
    });

    test(
      'en attente ou refusée : seuls les champs serveur sont posés',
      () async {
        await seed(syncStatus: 'SYNC_ERROR');
        await dao.applyPulled([_canonical()], schoolId: 'school-1', nowMs: 1);
        final r = await row();
        expect(r.title, 'Version locale');
        expect(r.syncStatus, 'SYNC_ERROR');
        expect(r.expenseNumber, 'DEP-0412');
      },
    );

    test(
      'un retrait descendu masque la ligne, sauf geste local en attente',
      () async {
        await seed(syncStatus: 'SYNCED');
        await dao.applyPulled(
          [_canonical(deletedAt: '2026-09-04T08:00:00.000Z')],
          schoolId: 'school-1',
          nowMs: 1,
        );
        expect((await row()).deletedAt, isNotNull);

        await db.update('expenses', {
          'deleted_at': null,
          'withdrawal_pending_at': _later,
        });
        await dao.applyPulled(
          [_canonical(deletedAt: '2026-09-04T08:00:00.000Z')],
          schoolId: 'school-1',
          nowMs: 2,
        );
        expect((await row()).deletedAt, isNull);
        // …mais ce que dit le serveur est gardé : un refus y reviendra.
        expect((await row()).serverDeletedAt, '2026-09-04T08:00:00.000Z');
      },
    );
  });

  group('refus', () {
    test('markRejected : la ligne porte son motif (A4)', () async {
      await seed();
      final marked = await dao.markRejected(
        'e-1',
        sentClientUpdatedAt: _sent,
        code: 'UNKNOWN_EXPENSE_TYPE',
        reason: 'UNKNOWN_EXPENSE_TYPE — type inconnu',
        nowMs: 1,
      );
      expect(marked, isTrue);
      final r = await row();
      expect(r.syncStatus, 'SYNC_ERROR');
      expect(r.syncErrorCode, 'UNKNOWN_EXPENSE_TYPE');
    });

    test(
      'markRejected : une correction arrivée pendant le vol n’est pas gelée',
      () async {
        await seed(clientUpdatedAt: _later);
        final marked = await dao.markRejected(
          'e-1',
          sentClientUpdatedAt: _sent,
          code: 'X',
          reason: 'x',
          nowMs: 1,
        );
        expect(marked, isFalse);
        expect((await row()).syncStatus, 'PENDING_SYNC');
      },
    );

    test(
      'revertWithdrawal : un retrait refusé fait revenir la ligne',
      () async {
        await seed(
          number: 'DEP-1',
          withdrawalPendingAt: _sent,
          deletedAt: _sent,
        );
        expect(
          await dao.revertWithdrawal('e-1', sentChangedAt: _sent, nowMs: 1),
          isTrue,
        );
        final r = await row();
        expect(r.deletedAt, isNull);
        expect(r.withdrawalPendingAt, isNull);
      },
    );

    test('revertWithdrawal : l’état rendu est celui du serveur — retirer, '
        'Annuler, restauration refusée ⇒ retirée', () async {
      await seed(
        number: 'DEP-1',
        withdrawalPendingAt: _later,
        serverDeletedAt: _sent,
      );
      expect(
        await dao.revertWithdrawal('e-1', sentChangedAt: _later, nowMs: 1),
        isTrue,
      );
      expect((await row()).deletedAt, _sent);
    });

    test(
      'revertWithdrawal : un geste plus récent attend → rien ne bouge',
      () async {
        await seed(
          number: 'DEP-1',
          withdrawalPendingAt: _later,
          deletedAt: _later,
        );
        expect(
          await dao.revertWithdrawal('e-1', sentChangedAt: _sent, nowMs: 1),
          isFalse,
        );
        expect((await row()).deletedAt, _later);
      },
    );

    test(
      'releaseWithdrawal : l’attente se lève, le geste local reste',
      () async {
        await seed(
          number: 'DEP-1',
          withdrawalPendingAt: _sent,
          deletedAt: _sent,
        );
        await dao.releaseWithdrawal('e-1', sentChangedAt: _sent, nowMs: 1);
        final r = await row();
        expect(r.withdrawalPendingAt, isNull);
        expect(r.deletedAt, _sent);
      },
    );
  });

  group('applyWithdrawalAck', () {
    test('le dernier geste est accusé : retrait posé, attente levée', () async {
      await seed(number: 'DEP-1', withdrawalPendingAt: _sent, deletedAt: _sent);
      await dao.applyWithdrawalAck(
        _canonical(deletedAt: '2026-09-03T09:00:01.000Z'),
        sentChangedAt: _sent,
        nowMs: 1,
      );
      final r = await row();
      expect(r.deletedAt, '2026-09-03T09:00:01.000Z');
      expect(r.withdrawalPendingAt, isNull);
    });

    test('un geste plus récent attend : il décidera, pas cet accusé', () async {
      // Retiré, puis restauré aussitôt (Annuler) : l'accusé du retrait revient.
      await seed(number: 'DEP-1', withdrawalPendingAt: _later);
      await dao.applyWithdrawalAck(
        _canonical(deletedAt: _sent),
        sentChangedAt: _sent,
        nowMs: 1,
      );
      final r = await row();
      expect(r.deletedAt, isNull);
      expect(r.withdrawalPendingAt, _later);
    });
  });
}
