import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/treasury/data/local/cash_pending_probe_sql.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../offline_full_db.dart';

/// Insère une ligne en complétant les colonnes obligatoires sans défaut par
/// une valeur neutre : le test ne dit que ce qui compte pour la sonde.
Future<void> _insert(
  Database db,
  String table,
  Map<String, Object?> values,
) async {
  final columns = await db.rawQuery('PRAGMA table_info($table)');
  final row = <String, Object?>{...values};
  for (final column in columns) {
    final name = column['name']! as String;
    final notNull = column['notnull'] == 1;
    final hasDefault = column['dflt_value'] != null;
    final primaryKey = column['pk'] == 1;
    if (row.containsKey(name) || !notNull || hasDefault) {
      if (primaryKey && !row.containsKey(name)) row[name] = name;
      continue;
    }
    final type = (column['type'] as String? ?? '').toUpperCase();
    row[name] = type.contains('INT') || type.contains('REAL') ? 0 : '';
  }
  await db.insert(table, row);
}

/// Une entrée d'outbox telle que l'écrivain réel la pose : identifiant
/// d'**entrée** `{type}:{id}`, et un identifiant d'**agrégat** qui n'est pas
/// toujours l'id de la ligne (la paie se range par ligne de paie).
Future<void> _outbox(
  Database db, {
  required String type,
  required String id,
  String? aggregateId,
  String status = 'PENDING',
}) => _insert(db, 'outbox', {
  'id': '$type:$id',
  'aggregate_type': type,
  'aggregate_id': aggregateId ?? id,
  'status': status,
});

const _inDay = '2026-10-22T09:15:00.000Z';
const _lastWeek = '2026-10-15T09:15:00.000Z';
const _payrollLine = 'payroll-line:2026-10:agent-1';

void main() {
  late Database db;
  late CashPendingProbeSql probe;

  setUp(() async {
    db = await openTenantTestDb();
    probe = CashPendingProbeSql(db);
  });
  tearDown(() => db.close());

  Future<int> usd() => probe.pendingFor(TreasuryCurrency.usd);
  Future<int> cdf() => probe.pendingFor(TreasuryCurrency.cdf);

  Future<void> payment(
    String id, {
    String paidAt = _inDay,
    String currency = 'USD',
    String outboxStatus = 'PENDING',
    String syncStatus = 'PENDING_SYNC',
  }) async {
    await _insert(db, 'payments', {
      'id': id,
      'paid_at': paidAt,
      'sync_status': syncStatus,
    });
    await _insert(db, 'payment_tenders', {
      'id': 't-$id',
      'payment_id': id,
      'currency': currency,
      'amount_in_cents': 5000,
    });
    await _outbox(db, type: 'PAYMENT', id: id, status: outboxStatus);
  }

  test('rien en attente : 0, la caisse peut se clôturer', () async {
    expect(await usd(), 0);
  });

  test(
    'un versement du jour en dollars bloque la caisse USD, pas la CDF',
    () async {
      await payment('p1');
      expect(await usd(), 1);
      expect(await cdf(), 0);
    },
  );

  test('un versement d un jour passé, resté sur la tablette, compte aussi : il '
      'manque à l ouverture d aujourd hui', () async {
    await payment('p1', paidAt: _lastWeek);
    expect(await usd(), 1);
  });

  test('un versement refusé (« à régulariser ») ne bloque plus', () async {
    await payment('p1', outboxStatus: 'SYNC_ERROR');
    expect(await usd(), 0);
  });

  test('un versement déjà envoyé ne compte pas', () async {
    await payment('p1', syncStatus: 'SYNCED');
    expect(await usd(), 0);
  });

  test('une vente boutique du jour en francs bloque la caisse CDF', () async {
    await _insert(db, 'boutique_sales', {
      'id': 's1',
      'sold_at': _inDay,
      'sync_status': 'PENDING_SYNC',
    });
    await _insert(db, 'boutique_sale_tenders', {
      'id': 'st1',
      'sale_id': 's1',
      'currency': 'CDF',
      'amount_in_cents': 1000000,
    });
    await _outbox(db, type: 'BOUTIQUE_SALE', id: 's1');
    expect(await cdf(), 1);
    expect(await usd(), 0);
  });

  test('un paiement de dépense en espèces compte ; par banque, non', () async {
    await _insert(db, 'expenses', {
      'id': 'e1',
      'currency': 'USD',
      'funding_source': 'CASH',
    });
    await _insert(db, 'expenses', {
      'id': 'e2',
      'currency': 'USD',
      'funding_source': 'BANK',
    });
    for (final expense in ['e1', 'e2']) {
      await _insert(db, 'expense_messages', {
        'id': 'm-$expense',
        'expense_id': expense,
        'act': 'PAYMENT',
        'created_at': _inDay,
        'sync_status': 'PENDING_SYNC',
      });
      await _outbox(
        db,
        type: 'EXPENSE_GESTURE',
        id: 'm-$expense',
        aggregateId: expense,
      );
    }
    expect(await usd(), 1);
  });

  test(
    'un paiement de dépense resté PENDING_SYNC sur une entrée morte ne bloque '
    'pas la caisse pour toujours',
    () async {
      await _insert(db, 'expenses', {
        'id': 'e1',
        'currency': 'USD',
        'funding_source': 'CASH',
      });
      await _insert(db, 'expense_messages', {
        'id': 'm1',
        'expense_id': 'e1',
        'act': 'PAYMENT',
        'created_at': _inDay,
        'sync_status': 'PENDING_SYNC',
      });
      await _outbox(
        db,
        type: 'EXPENSE_GESTURE',
        id: 'm1',
        aggregateId: 'e1',
        status: 'SYNC_ERROR',
      );
      expect(await usd(), 0);
    },
  );

  test('un salaire versé en espèces compte ; par mobile money, non', () async {
    for (final (id, mode) in [('d1', 'CASH'), ('d2', 'MOBILE_MONEY')]) {
      await _insert(db, 'payroll_disbursements', {
        'id': id,
        'currency': 'CDF',
        'mode': mode,
        'paid_at': _inDay,
        'sync_status': 'PENDING_SYNC',
      });
      // L'agrégat d'un versement est sa ligne de paie, pas le versement.
      await _outbox(
        db,
        type: 'PAYROLL_DISBURSEMENT',
        id: id,
        aggregateId: _payrollLine,
      );
    }
    expect(await cdf(), 1);
  });

  test('une avance en espèces et son annulation comptent chacune', () async {
    await _insert(db, 'salary_advances', {
      'id': 'a1',
      'currency': 'USD',
      'mode': 'CASH',
      'cancellation_id': 'x1',
    });
    await _outbox(
      db,
      type: 'SALARY_ADVANCE',
      id: 'a1',
      aggregateId: 'payroll:2026-10',
    );
    expect(await usd(), 1);
    await _outbox(
      db,
      type: 'SALARY_ADVANCE_CANCELLATION',
      id: 'x1',
      aggregateId: 'advance:a1',
    );
    expect(await usd(), 2);
  });

  test('l annulation d un salaire versé en espèces compte', () async {
    await _insert(db, 'payroll_disbursements', {
      'id': 'd1',
      'currency': 'CDF',
      'mode': 'CASH',
      'paid_at': _lastWeek,
      'sync_status': 'SYNCED',
      'cancellation_id': 'k1',
    });
    await _outbox(
      db,
      type: 'PAYROLL_DISBURSEMENT_CANCELLATION',
      id: 'k1',
      aggregateId: _payrollLine,
    );
    expect(await cdf(), 1);
  });

  test('une annulation du jour, sur un versement en dollars déjà envoyé, '
      'bloque la caisse USD', () async {
    await payment('p1', syncStatus: 'SYNCED', outboxStatus: 'ACKED');
    await _insert(db, 'payment_corrections', {
      'id': 'c1',
      'payment_id': 'p1',
      'status': 'PENDING',
      'cash_moved': 1,
      'client_cancelled_at': _inDay,
    });
    await _outbox(db, type: 'PAYMENT_CORRECTION', id: 'c1');
    expect(await usd(), 1);
  });

  test('les familles s additionnent', () async {
    await payment('p1');
    await payment('p2');
    await _insert(db, 'payroll_disbursements', {
      'id': 'd1',
      'currency': 'USD',
      'mode': 'CASH',
      'paid_at': _inDay,
      'sync_status': 'PENDING_SYNC',
    });
    await _outbox(
      db,
      type: 'PAYROLL_DISBURSEMENT',
      id: 'd1',
      aggregateId: _payrollLine,
    );
    expect(await usd(), 3);
  });
}
