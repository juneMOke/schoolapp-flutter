import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v29 — `payments.collected_by_id` / `collected_by_name`.
///
/// Ce que les colonnes rendent possible : nommer l'encaisseur d'un versement
/// venu d'un AUTRE guichet. Le poste qui encaisse stampe ses `cashier_*`
/// (v19), mais rien de local n'existe pour un versement arrivé par pull — et
/// l'écran de détail affichait jusqu'ici un « Encaissé par » vide, non par
/// oubli mais parce qu'aucun contrat de synchro ne portait le nom. Le back le
/// transporte désormais ; voici où il se pose.
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

  /// La table `payments` telle qu'elle existait à la v28 : le numéro du payeur
  /// est là, l'encaisseur attribué par le serveur non.
  Future<void> createV28Payments() async {
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        client_uuid TEXT NOT NULL,
        student_id TEXT NOT NULL,
        academic_year_id TEXT,
        amount_in_cents INTEGER NOT NULL,
        currency TEXT NOT NULL,
        method TEXT NOT NULL DEFAULT 'CASH',
        paid_at TEXT NOT NULL,
        payer_first_name TEXT NOT NULL,
        payer_last_name TEXT NOT NULL,
        payer_middle_name TEXT,
        payer_phone_number TEXT,
        status TEXT,
        cashier_uid TEXT,
        cashier_first_name TEXT,
        cashier_last_name TEXT,
        device_id TEXT,
        receipt_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
        sync_error TEXT,
        synced_at INTEGER,
        updated_at INTEGER NOT NULL DEFAULT 0,
        ticket_printed_at INTEGER
      )
    ''');
  }

  /// Le montant n'est écrit que si la colonne EXISTE encore.
  ///
  /// Ce helper sert des deux côtés de la migration : avant, la table est dans
  /// sa forme d'époque et `amount_in_cents` y est `NOT NULL` ; après le palier
  /// v34, elle ne l'a plus — le versement dérive ses montants de ses
  /// imputations. Se caler sur la forme réelle évite de dupliquer le seed.
  Future<void> seedLocalPayment(String id) async {
    final columns = {
      for (final c in await db.rawQuery('PRAGMA table_info(payments)'))
        c['name'] as String,
    };
    await db.insert('payments', {
      'id': id,
      'client_uuid': id,
      'student_id': 's-1',
      'academic_year_id': 'y-1',
      'paid_at': '2026-08-24T09:30:00.000Z',
      'payer_first_name': 'Joseph',
      'payer_last_name': 'Kabongo',
      // Encaissé ICI : le poste a stampé son caissier.
      'cashier_uid': 'u-7',
      'cashier_first_name': 'Alice',
      'cashier_last_name': 'Mbayo',
      'updated_at': 0,
      if (columns.contains('amount_in_cents')) 'amount_in_cents': 150000,
      if (columns.contains('currency')) 'currency': 'CDF',
    });
  }

  Future<Set<String>> columnNames() async {
    final columns = await db.rawQuery('PRAGMA table_info(payments)');
    return {for (final column in columns) column['name'] as String};
  }

  Future<void> migrateFrom(int oldVersion) =>
      migrateOfflineDatabase(db, oldVersion, buildOfflineSchema());

  test(
    'ajoute les deux colonnes sans toucher aux versements existants',
    () async {
      await createV28Payments();
      await seedLocalPayment('pay-1');

      await migrateFrom(28);

      expect(columnNames(), completion(contains('collected_by_id')));
      expect(columnNames(), completion(contains('collected_by_name')));

      // Aucun backfill, et surtout aucun souhaitable : recopier le caissier
      // local ici inventerait une attribution SERVEUR jamais prononcée.
      final row = await db.query(
        'payments',
        where: 'id = ?',
        whereArgs: ['pay-1'],
      );
      expect(row.single['collected_by_id'], isNull);
      expect(row.single['collected_by_name'], isNull);
      // Ce que le poste a stampé reste intact.
      expect(row.single['cashier_first_name'], 'Alice');
    },
  );

  test(
    'les colonnes restent NULLABLES — un versement sans elles s\'écrit',
    () async {
      await createV28Payments();
      await migrateFrom(28);

      await expectLater(seedLocalPayment('pay-legacy'), completes);
    },
  );

  test('l\'attribution serveur se pose et se relit', () async {
    await createV28Payments();
    await seedLocalPayment('pay-1');
    await migrateFrom(28);

    await db.update(
      'payments',
      {'collected_by_id': 'u-42', 'collected_by_name': 'Sarah Moke'},
      where: 'id = ?',
      whereArgs: ['pay-1'],
    );

    final rows = await db.query(
      'payments',
      columns: const ['collected_by_id', 'collected_by_name'],
      where: 'id = ?',
      whereArgs: ['pay-1'],
    );
    expect(rows.single['collected_by_id'], 'u-42');
    expect(rows.single['collected_by_name'], 'Sarah Moke');
  });

  /// Une base traverse plusieurs versions d'affilée, et certains paliers
  /// recréent des tables depuis le DDL canonique — lequel porte déjà les
  /// colonnes. Sans la garde `_hasColumn`, `duplicate column name` ferait
  /// échouer l'escalier entier.
  test('le palier v29 se rejoue sans lever', () async {
    await createV28Payments();
    await seedLocalPayment('pay-1');

    await migrateFrom(28);
    await expectLater(migrateFrom(28), completes);

    expect(columnNames(), completion(contains('collected_by_name')));
    expect(await db.query('payments'), hasLength(1));
  });

  /// Le migrateur s'exerce aussi sur des bases PARTIELLES : un `ALTER` sur une
  /// table absente ferait échouer l'escalier entier, donc tous les autres
  /// paliers.
  test('ne touche pas une base où payments n\'existe pas', () async {
    await db.execute('CREATE TABLE autre_chose (id TEXT PRIMARY KEY)');

    await expectLater(migrateFrom(28), completes);
  });

  test('une base neuve porte les colonnes sans migration', () async {
    final payments = buildOfflineSchema().firstWhere(
      (table) => table.name == 'payments',
    );

    // Le DDL canonique doit rester d'accord avec la migration : sinon les
    // colonnes n'existeraient que sur les installations mises à jour, ou que
    // sur les neuves — deux parcs qui divergent en silence.
    expect(payments.createTableSql, contains('collected_by_id TEXT'));
    expect(payments.createTableSql, contains('collected_by_name TEXT'));
  });
}
