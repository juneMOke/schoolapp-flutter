import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v28 — `payments.payer_phone_number`.
///
/// Ce que la colonne rend possible : rappeler le payeur, et surtout le
/// RETROUVER au versement suivant. Sans elle, le numéro exigé au guichet
/// partirait vers le serveur sans jamais revenir, et l'annuaire local n'aurait
/// rien à rapprocher — le guichetier ressaisirait tout à chaque trimestre.
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

  /// La table `payments` telle qu'elle existait AVANT la v28 : la trace
  /// d'impression de la v25 est là, le numéro du payeur non.
  Future<void> createLegacyPayments() async {
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
  Future<void> seedPayment(String id) async {
    final columns = {
      for (final c in await db.rawQuery('PRAGMA table_info(payments)'))
        c['name'] as String,
    };
    await db.insert('payments', {
      'id': id,
      'client_uuid': id,
      'student_id': 's-1',
      'academic_year_id': 'y-1',
      'paid_at': '2026-08-12T09:30:00.000Z',
      'payer_first_name': 'Joseph',
      'payer_last_name': 'Kabongo',
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

  test('ajoute le numéro sans toucher aux versements existants', () async {
    await createLegacyPayments();
    await seedPayment('pay-1');
    await seedPayment('pay-2');

    await migrateFrom(27);

    expect(columnNames(), completion(contains('payer_phone_number')));

    // Aucun backfill, et c'est délibéré : le tuteur de l'élève n'est PAS le
    // payeur — c'est précisément ce que la saisie établit. Recopier un numéro
    // de tuteur ici inventerait un fait, et l'annuaire proposerait ensuite un
    // numéro que personne n'a donné à la caisse.
    final rows = await db.query('payments', orderBy: 'id');
    expect(rows, hasLength(2));
    expect(rows.every((r) => r['payer_phone_number'] == null), isTrue);
  });

  test(
    'la colonne reste NULLABLE — un versement sans numéro s\'écrit',
    () async {
      await createLegacyPayments();
      await migrateFrom(27);

      // Un `NOT NULL` aurait obligé à replier sur `''`, rendant « pas de
      // numéro » indiscernable de « numéro inconnu » au moment précis où
      // l'annuaire doit choisir entre proposer ce payeur et le taire.
      await expectLater(seedPayment('pay-legacy'), completes);
      final row = await db.query(
        'payments',
        where: 'id = ?',
        whereArgs: ['pay-legacy'],
      );
      expect(row.single['payer_phone_number'], isNull);
    },
  );

  test('le numéro se pose et se relit', () async {
    await createLegacyPayments();
    await seedPayment('pay-1');
    await migrateFrom(27);

    await db.update(
      'payments',
      {'payer_phone_number': '+243816939060'},
      where: 'id = ?',
      whereArgs: ['pay-1'],
    );

    final rows = await db.query(
      'payments',
      columns: const ['payer_phone_number'],
      where: 'id = ?',
      whereArgs: ['pay-1'],
    );
    expect(rows.single['payer_phone_number'], '+243816939060');
  });

  /// Le palier doit pouvoir être rejoué : une base traverse plusieurs versions
  /// d'affilée, et certains paliers recréent des tables depuis le DDL
  /// canonique — lequel porte déjà la colonne. Sans la garde `_hasColumn`,
  /// `duplicate column name` ferait échouer l'escalier entier.
  test('le palier v28 se rejoue sans lever', () async {
    await createLegacyPayments();
    await seedPayment('pay-1');

    await migrateFrom(27);
    await expectLater(migrateFrom(27), completes);

    expect(columnNames(), completion(contains('payer_phone_number')));
    expect(await db.query('payments'), hasLength(1));
  });

  /// Le migrateur s'exerce aussi sur des bases PARTIELLES : chaque test de
  /// palier ne crée que les tables qui le concernent. Un `ALTER` sur une table
  /// absente ferait échouer l'escalier entier — donc tous les autres paliers.
  test('ne touche pas une base où payments n\'existe pas', () async {
    await db.execute('CREATE TABLE autre_chose (id TEXT PRIMARY KEY)');

    await expectLater(migrateFrom(27), completes);
  });

  test('une base neuve porte la colonne sans migration', () async {
    final payments = buildOfflineSchema().firstWhere(
      (table) => table.name == 'payments',
    );

    // Le DDL canonique doit rester d'accord avec la migration : sinon la
    // colonne n'existerait que sur les installations mises à jour, ou que sur
    // les neuves — deux parcs qui divergent en silence.
    expect(payments.createTableSql, contains('payer_phone_number TEXT'));
  });
}
