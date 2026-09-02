import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v41 — `payment_tenders`, et son **backfill identité**.
///
/// Ce que la table rend possible : lire ce qui est entré dans le tiroir dans sa
/// propre unité, à côté de ce qui a éteint la dette.
///
/// Le backfill n'est pas une commodité. Le pull des paiements est un delta par
/// curseur : les versements déjà en base locale ne seront jamais retouchés et
/// resteraient sans tender pour toujours. La seule alternative serait un repli
/// « pas de tender ⇒ lire les allocations » à la lecture — deux voies, et
/// celles-là divergent toujours une fois.
bool _ffiInitialized = false;

Future<Database> _openLegacyDb() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
}

void main() {
  late Database db;

  setUp(() async => db = await _openLegacyDb());
  tearDown(() async => db.close());

  Future<void> migrateFrom(int oldVersion, {int? newVersion}) =>
      migrateOfflineDatabase(
        db,
        oldVersion,
        buildOfflineSchema(),
        newVersion: newVersion ?? 41,
      );

  /// `payment_allocations` telle qu'elle existe à la v40.
  Future<void> createLegacyAllocations() async {
    await db.execute('''
      CREATE TABLE payment_allocations (
        id TEXT PRIMARY KEY,
        client_uuid TEXT NOT NULL,
        payment_id TEXT NOT NULL,
        student_charge_id TEXT,
        fee_tariff_id TEXT,
        fee_code TEXT NOT NULL,
        student_charge_label TEXT NOT NULL,
        amount_in_cents INTEGER NOT NULL,
        currency TEXT NOT NULL
      )
    ''');
  }

  Future<void> seedAllocation(
    String id, {
    required String paymentId,
    required int amountInCents,
    required String currency,
    String feeCode = 'MINERVAL_T1',
  }) => db.insert('payment_allocations', {
    'id': id,
    'client_uuid': id,
    'payment_id': paymentId,
    'student_charge_id': 'chg-$id',
    'fee_code': feeCode,
    'student_charge_label': 'Minerval — tranche 1',
    'amount_in_cents': amountInCents,
    'currency': currency,
  });

  Future<bool> hasTable(String name) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [name],
    );
    return rows.isNotEmpty;
  }

  test('crée la table sur une base qui monte de la v40', () async {
    await createLegacyAllocations();

    await migrateFrom(40);

    expect(await hasTable('payment_tenders'), isTrue);
    final columns = await db.rawQuery('PRAGMA table_info(payment_tenders)');
    expect(
      {for (final column in columns) column['name'] as String},
      containsAll(<String>[
        'id',
        'client_uuid',
        'payment_id',
        'amount_in_cents',
        'currency',
        'rate_micros',
        'pivot_currency',
      ]),
    );
  });

  test(
    'backfille une ligne d’identité par versement — perçu = imputé',
    () async {
      await createLegacyAllocations();
      await seedAllocation(
        'al-1',
        paymentId: 'pay-1',
        amountInCents: 3000,
        currency: 'USD',
      );

      await migrateFrom(40);

      final tender = (await db.query('payment_tenders')).single;
      expect(tender['payment_id'], 'pay-1');
      expect(tender['amount_in_cents'], 3000);
      expect(tender['currency'], 'USD');
      // Taux 1 : avant la V2, il n'existait aucun moyen d'encaisser dans une
      // autre devise que celle de la créance.
      expect(tender['rate_micros'], 1000000);
      expect(tender['pivot_currency'], 'USD');
    },
  );

  test(
    'agrège les imputations d’un même versement, devise par devise',
    () async {
      await createLegacyAllocations();
      await seedAllocation(
        'al-1',
        paymentId: 'pay-1',
        amountInCents: 3000,
        currency: 'USD',
      );
      await seedAllocation(
        'al-2',
        paymentId: 'pay-1',
        amountInCents: 1500,
        currency: 'USD',
      );
      await seedAllocation(
        'al-3',
        paymentId: 'pay-1',
        amountInCents: 9000000,
        currency: 'CDF',
      );

      await migrateFrom(40);

      final tenders = await db.query('payment_tenders', orderBy: 'currency');
      expect(tenders, hasLength(2));
      // Un versement à deux devises produit deux lignes : les unités diffèrent,
      // donc les pivots aussi. Jamais une somme.
      expect(tenders.first['currency'], 'CDF');
      expect(tenders.first['amount_in_cents'], 9000000);
      expect(tenders.last['currency'], 'USD');
      expect(tenders.last['amount_in_cents'], 4500);
    },
  );

  test('deux versements ne se mélangent pas', () async {
    await createLegacyAllocations();
    await seedAllocation(
      'al-1',
      paymentId: 'pay-1',
      amountInCents: 3000,
      currency: 'USD',
    );
    await seedAllocation(
      'al-2',
      paymentId: 'pay-2',
      amountInCents: 5000,
      currency: 'USD',
    );

    await migrateFrom(40);

    final tenders = await db.query('payment_tenders', orderBy: 'payment_id');
    expect(tenders.map((t) => t['payment_id']), ['pay-1', 'pay-2']);
    expect(tenders.map((t) => t['amount_in_cents']), [3000, 5000]);
  });

  test('chaque ligne reçoit un identifiant propre', () async {
    await createLegacyAllocations();
    await seedAllocation(
      'al-1',
      paymentId: 'pay-1',
      amountInCents: 3000,
      currency: 'USD',
    );
    await seedAllocation(
      'al-2',
      paymentId: 'pay-1',
      amountInCents: 9000000,
      currency: 'CDF',
    );

    await migrateFrom(40);

    final ids = (await db.query('payment_tenders')).map((t) => t['id']).toSet();
    expect(ids, hasLength(2));
    expect(ids.every((id) => (id as String).length == 36), isTrue);
  });

  test('le palier est rejouable : rien n’est compté deux fois', () async {
    await createLegacyAllocations();
    await seedAllocation(
      'al-1',
      paymentId: 'pay-1',
      amountInCents: 3000,
      currency: 'USD',
    );

    await migrateFrom(40);
    final premier = (await db.query('payment_tenders')).single;

    await migrateFrom(40);

    final apres = await db.query('payment_tenders');
    expect(apres, hasLength(1));
    // Rejoué, il ne réécrit pas non plus la ligne : `INSERT OR REPLACE` aurait
    // changé l'identifiant sous les pieds d'un ticket déjà imprimé.
    expect(apres.single['id'], premier['id']);
  });

  test(
    'un versement encaissé APRÈS le palier n’est pas backfillé en double',
    () async {
      await createLegacyAllocations();
      await seedAllocation(
        'al-1',
        paymentId: 'pay-1',
        amountInCents: 3000,
        currency: 'USD',
      );
      await migrateFrom(40);

      // Le guichet encaisse : la ligne d'imputation ET son tender sont écrits
      // ensemble par le chemin d'écriture.
      await seedAllocation(
        'al-2',
        paymentId: 'pay-2',
        amountInCents: 5000,
        currency: 'USD',
      );
      await db.insert('payment_tenders', {
        'id': 'tnd-2',
        'client_uuid': 'tnd-2',
        'payment_id': 'pay-2',
        'amount_in_cents': 5000,
        'currency': 'USD',
        'rate_micros': 1000000,
        'pivot_currency': 'USD',
      });

      await migrateFrom(40);

      final tenders = await db.query(
        'payment_tenders',
        where: 'payment_id = ?',
        whereArgs: ['pay-2'],
      );
      expect(tenders, hasLength(1));
      expect(tenders.single['id'], 'tnd-2');
    },
  );

  test('une base sans imputation passe le palier sans lever', () async {
    // Tablette neuve : la table naît vide, il n'y a rien à combler.
    await migrateFrom(40);
    expect(await hasTable('payment_tenders'), isTrue);
    expect(await db.query('payment_tenders'), isEmpty);
  });

  test('newVersion borne l’escalier : sans la v41, pas de table', () async {
    await createLegacyAllocations();
    await migrateFrom(40, newVersion: 40);
    expect(await hasTable('payment_tenders'), isFalse);
  });
}
