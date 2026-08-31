import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v25 — trace d'impression du ticket de perception.
///
/// Ce que la colonne rend possible : n'offrir le rattrapage d'impression que
/// là où aucun papier n'est sorti. Sans elle, un bouton « imprimer » sur un
/// paiement déjà servi serait une réimpression — ce que l'ADR-013 interdit —
/// et rien dans la base ne permettait de distinguer les deux cas : la ligne de
/// `generated_documents` d'un paiement n'existe qu'après le scellement serveur.
///
/// ⚠️ **v24 est sautée volontairement** : la branche `feature/auth_permissions`
/// la consomme déjà. Deux migrations sous un même numéro seraient invisibles
/// jusqu'au terrain — la base marquée à jour ne rejouerait jamais la seconde.
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

  /// La table `payments` telle qu'elle existait AVANT la v25 : les colonnes
  /// caissier de la v19 sont là, la trace d'impression non.
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
        updated_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> seedPayment(String id) => db.insert('payments', {
    'id': id,
    'client_uuid': id,
    // La table est ici dans sa forme d'ÉPOQUE : le montant y est encore
    // NOT NULL, et cette insertion précède la migration.
    'amount_in_cents': 150000,
    'currency': 'CDF',
    'student_id': 's-1',
    'academic_year_id': 'y-1',
    'paid_at': '2026-08-12T09:30:00.000Z',
    'payer_first_name': 'Joseph',
    'payer_last_name': 'Kabongo',
    'updated_at': 0,
  });

  Future<Set<String>> columnNames() async {
    final columns = await db.rawQuery('PRAGMA table_info(payments)');
    return {for (final column in columns) column['name'] as String};
  }

  Future<void> migrateFrom(int oldVersion) =>
      migrateOfflineDatabase(db, oldVersion, buildOfflineSchema());

  test('ajoute la trace sans toucher aux versements existants', () async {
    await createLegacyPayments();
    await seedPayment('pay-1');
    await seedPayment('pay-2');

    await migrateFrom(23);

    expect(columnNames(), completion(contains('ticket_printed_at')));

    // Aucun backfill, et c'est délibéré : personne ne peut plus dire si ces
    // versements ont été servis. Ils restent donc éligibles au rattrapage —
    // le pire cas acceptable, un papier de trop valant mieux qu'aucun.
    final rows = await db.query('payments', orderBy: 'id');
    expect(rows, hasLength(2));
    expect(rows.every((r) => r['ticket_printed_at'] == null), isTrue);
  });

  test('la trace se pose et se relit', () async {
    await createLegacyPayments();
    await seedPayment('pay-1');
    await migrateFrom(23);

    await db.update(
      'payments',
      {'ticket_printed_at': 1786500000000},
      where: 'id = ?',
      whereArgs: ['pay-1'],
    );

    final rows = await db.query(
      'payments',
      columns: const ['ticket_printed_at'],
      where: 'id = ?',
      whereArgs: ['pay-1'],
    );
    expect(rows.single['ticket_printed_at'], 1786500000000);
  });

  /// Le palier doit pouvoir être rejoué : une base peut traverser plusieurs
  /// versions d'affilée, et certains paliers recréent des tables depuis le DDL
  /// canonique — lequel porte déjà la colonne. Sans la garde `_hasColumn`,
  /// `duplicate column name` ferait échouer l'escalier entier.
  ///
  /// ⚠️ On rejoue depuis 23, pas depuis 1 : les paliers les plus anciens
  /// supposent une base complète, alors que ce test n'en crée qu'une table.
  /// Ce qui est vérifié ici est l'idempotence de la v25, pas celle de
  /// l'escalier — les autres paliers ont leurs propres tests.
  test('le palier v25 se rejoue sans lever', () async {
    await createLegacyPayments();
    await seedPayment('pay-1');

    await migrateFrom(23);
    await expectLater(migrateFrom(23), completes);
    await expectLater(migrateFrom(24), completes);

    expect(columnNames(), completion(contains('ticket_printed_at')));
    // Le rejeu n'a pas effacé la ligne au passage.
    expect(await db.query('payments'), hasLength(1));
  });

  /// Le migrateur s'exerce aussi sur des bases PARTIELLES : chaque test de
  /// palier ne crée que les tables qui le concernent, et la suite complète en
  /// compte des dizaines. Un `ALTER` sur une table absente ferait échouer
  /// l'escalier entier — donc tous les autres paliers, pas seulement celui-ci.
  ///
  /// C'est exactement ce qui s'est produit : 68 tests rouges pour une garde
  /// `_hasTable` oubliée, qu'aucun test de ce fichier ne pouvait voir puisqu'ils
  /// créent tous `payments`.
  test('ne touche pas une base où payments n\'existe pas', () async {
    await db.execute('CREATE TABLE autre_chose (id TEXT PRIMARY KEY)');

    await expectLater(migrateFrom(23), completes);
  });

  test('une base neuve porte la colonne sans migration', () async {
    final payments = buildOfflineSchema().firstWhere(
      (table) => table.name == 'payments',
    );

    // Le DDL canonique doit rester d'accord avec la migration : sinon la
    // colonne n'existerait que sur les installations mises à jour, ou que sur
    // les neuves — deux parcs qui divergent en silence.
    expect(payments.createTableSql, contains('ticket_printed_at INTEGER'));
  });
}
