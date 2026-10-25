import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_rh_visibility.dart';
import 'package:school_app_flutter/features/expense/data/repositories/expense_pull_repository_impl.dart';

import '../../../offline_full_db.dart';

/// Le bloc R.H. est caviardé à la descente : un poste qui gagne `hr.pay.read`
/// reprend le flux des dépenses depuis le début, sinon les avances déjà
/// reçues sans leur bloc ne redescendraient jamais.
void main() {
  late Database db;
  late SyncMetaDao syncMeta;
  final cursor = expensesCursorKey('s-1');

  ExpenseRhVisibility visibility(bool? reads) => ExpenseRhVisibility(
    syncMetaDao: syncMeta,
    readsPayroll: () async => reads,
    now: () => 5000,
  );

  Future<void> advanced() =>
      syncMeta.setCursor(cursor, cursor: 'page-9', syncedAt: 100);

  setUp(() async {
    db = await openFullOfflineDb();
    syncMeta = SyncMetaDao(db);
  });

  tearDown(() async => db.close());

  test('le droit gagné rembobine le flux, une seule fois', () async {
    await advanced();
    await visibility(false).rewindIfGained('s-1', cursor);
    expect(await syncMeta.getCursor(cursor), 'page-9');

    expect(await visibility(true).rewindIfGained('s-1', cursor), isTrue);
    expect(await syncMeta.getCursor(cursor), isNull);

    await advanced();
    expect(await visibility(true).rewindIfGained('s-1', cursor), isFalse);
    expect(await syncMeta.getCursor(cursor), 'page-9');
  });

  test('marqueur absent avec le droit : on rembobine', () async {
    await advanced();

    expect(await visibility(true).rewindIfGained('s-1', cursor), isTrue);
    expect(await syncMeta.getCursor(cursor), isNull);
  });

  test('perdu puis regagné : on rembobine de nouveau', () async {
    await visibility(true).rewindIfGained('s-1', cursor);
    await visibility(false).rewindIfGained('s-1', cursor);
    await advanced();

    expect(await visibility(true).rewindIfGained('s-1', cursor), isTrue);
  });

  test('droits inconnus : rien ne bouge, le marqueur non plus', () async {
    await advanced();

    expect(await visibility(null).rewindIfGained('s-1', cursor), isFalse);
    expect(await syncMeta.getCursor(cursor), 'page-9');
    expect(
      await syncMeta.getCursor(ExpenseRhVisibility.markerKey('s-1')),
      isNull,
    );
  });

  test('le marqueur échappe au balayage des curseurs du flux', () async {
    await visibility(true).rewindIfGained('s-1', cursor);
    await syncMeta.deleteCursorsOf('expenses');

    expect(
      await syncMeta.getCursor(ExpenseRhVisibility.markerKey('s-1')),
      'granted',
    );
  });
}
