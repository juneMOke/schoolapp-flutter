import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_dao.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_models.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_removal_hooks.dart';

import '../offline_full_test_db.dart';

/// Les octets hors base d'une ligne retirée : prévenus après l'effacement,
/// jamais pour un retrait qui ne s'applique pas.
void main() {
  late Database db;
  late TombstoneRemovalHooks hooks;
  late TombstoneDao dao;
  late List<String> called;

  setUp(() async {
    db = await openFullOfflineDb();
    hooks = TombstoneRemovalHooks();
    called = [];
    hooks.add('finance_payments', (id) async => called.add(id));
    dao = TombstoneDao(db, SyncMetaDao(db), hooks: hooks);
  });
  tearDown(() async => db.close());

  Future<void> givenPayment(String id, {String status = 'SYNCED'}) =>
      db.insert('payments', {
        'id': id,
        'client_uuid': id,
        'student_id': 'eleve-1',
        'paid_at': '2026-09-01T08:00:00Z',
        'sync_status': status,
        'updated_at': 0,
      });

  TombstoneDto removal(String id) => TombstoneDto(
    resource: 'finance_payments',
    entityId: id,
    reason: TombstoneReason.deleted,
  );

  test('une ligne retirée prévient son module', () async {
    await givenPayment('pay-1');
    await dao.apply([removal('pay-1')]);
    expect(called, ['pay-1']);
  });

  test('un retrait différé (écriture locale non poussée) ne prévient '
      'personne', () async {
    await givenPayment('pay-1', status: 'PENDING_SYNC');
    await dao.apply([removal('pay-1')]);
    expect(called, isEmpty);
  });

  test('une ligne absente ne prévient personne', () async {
    await dao.apply([removal('pay-x')]);
    expect(called, isEmpty);
  });

  test('un crochet qui échoue n\'arrête pas le retrait', () async {
    hooks.add('finance_payments', (_) async => throw StateError('disque'));
    await givenPayment('pay-1');
    await givenPayment('pay-2');
    final result = await dao.apply([removal('pay-1'), removal('pay-2')]);
    expect(result.removed, 2);
    expect(called, ['pay-1', 'pay-2']);
  });
}
