import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/models/payment_allocation_local_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v38 — `payment_allocations.fee_tariff_id`.
///
/// Ce que la colonne rend possible : dire sur QUELLE TRANCHE l'argent a été
/// reçu. Depuis que le serveur admet plusieurs lignes de grille d'une même
/// nature sur un niveau (un minerval en sept tranches), `fee_code` ne départage
/// plus deux créances et le serveur refuse d'imputer au hasard — 422
/// `AMBIGUOUS_FEE_CODE`, sur de l'argent déjà dans le tiroir et un reçu déjà
/// imprimé.
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

  /// `payment_allocations` telle qu'elle existait AVANT la v38 : l'imputation
  /// nomme la nature du frais, pas la ligne de grille.
  Future<void> createLegacyAllocations() async {
    await db.execute('''
      CREATE TABLE payment_allocations (
        id TEXT PRIMARY KEY,
        client_uuid TEXT NOT NULL,
        payment_id TEXT NOT NULL,
        student_charge_id TEXT,
        fee_code TEXT NOT NULL,
        student_charge_label TEXT NOT NULL,
        amount_in_cents INTEGER NOT NULL,
        currency TEXT NOT NULL
      )
    ''');
  }

  Future<void> seedAllocation(String id) => db.insert('payment_allocations', {
    'id': id,
    'client_uuid': id,
    'payment_id': 'pay-1',
    'student_charge_id': 'charge-$id',
    'fee_code': 'EXAMINATION',
    'student_charge_label': 'Organisation matériel examens — 2/3',
    'amount_in_cents': 500000,
    'currency': 'CDF',
  });

  Future<Set<String>> columnNames() async {
    final columns = await db.rawQuery('PRAGMA table_info(payment_allocations)');
    return {for (final column in columns) column['name'] as String};
  }

  Future<void> migrateFrom(int oldVersion) =>
      migrateOfflineDatabase(db, oldVersion, buildOfflineSchema());

  test('ajoute le tarif sans toucher aux imputations existantes', () async {
    await createLegacyAllocations();
    await seedAllocation('alloc-1');
    await seedAllocation('alloc-2');

    await migrateFrom(37);

    expect(columnNames(), completion(contains('fee_tariff_id')));

    // Aucun backfill, et c'est délibéré : retrouver la ligne de grille visée
    // suppose de lire le grand-livre, ce qui n'est pas un geste de schéma. Ces
    // imputations gardent `NULL`, qui se lit « on ne sait pas encore », et la
    // reprise des versements en attente les renseignera — quand la table des
    // créances sera elle-même juste.
    final rows = await db.query('payment_allocations', orderBy: 'id');
    expect(rows, hasLength(2));
    expect(rows.every((r) => r['fee_tariff_id'] == null), isTrue);
    expect(rows.first['amount_in_cents'], 500000);
  });

  test('le tarif se pose, et se relit par le modèle', () async {
    await createLegacyAllocations();
    await seedAllocation('alloc-1');
    await migrateFrom(37);

    await db.update(
      'payment_allocations',
      {'fee_tariff_id': '1d763648-70e0-4272-8ca1-224db48adfd1'},
      where: 'id = ?',
      whereArgs: ['alloc-1'],
    );

    final row = await db.query(
      'payment_allocations',
      where: 'id = ?',
      whereArgs: ['alloc-1'],
    );
    final model = PaymentAllocationLocalModel.fromMap(row.single);
    expect(model.feeTariffId, '1d763648-70e0-4272-8ca1-224db48adfd1');
  });

  /// Le palier doit pouvoir être rejoué : une base traverse plusieurs versions
  /// d'affilée, et certains paliers recréent des tables depuis le DDL canonique
  /// — lequel porte déjà la colonne. Sans la garde `_hasColumn`,
  /// `duplicate column name` ferait échouer l'escalier entier.
  test('le palier v38 se rejoue sans lever', () async {
    await createLegacyAllocations();
    await seedAllocation('alloc-1');

    await migrateFrom(37);
    await expectLater(migrateFrom(37), completes);

    expect(columnNames(), completion(contains('fee_tariff_id')));
    expect(await db.query('payment_allocations'), hasLength(1));
  });

  /// Le migrateur s'exerce aussi sur des bases PARTIELLES : chaque test de
  /// palier ne crée que les tables qui le concernent. Un `ALTER` sur une table
  /// absente ferait échouer l'escalier entier — donc tous les autres paliers.
  test('ne touche pas une base où payment_allocations n\'existe pas', () async {
    await db.execute('CREATE TABLE autre_chose (id TEXT PRIMARY KEY)');

    await expectLater(migrateFrom(37), completes);
  });

  test('une base neuve porte la colonne sans migration', () async {
    final allocations = buildOfflineSchema().firstWhere(
      (table) => table.name == 'payment_allocations',
    );

    // Le DDL canonique doit rester d'accord avec la migration : sinon la
    // colonne n'existerait que sur les installations mises à jour, ou que sur
    // les neuves — deux parcs qui divergent en silence.
    expect(allocations.createTableSql, contains('fee_tariff_id TEXT'));
  });

  /// Le tarif est FIGÉ à l'encaissement, comme le libellé. `PaymentDelta` ne le
  /// porte pas : le DTO du pull le laisse donc à `null`, et l'écrire effacerait
  /// — au premier delta qui repasse sur la ligne — la seule information qui dise
  /// sur quelle tranche l'argent a été reçu.
  test('le patch de pull n\'efface jamais le tarif figé', () {
    final patch = const PaymentAllocationLocalModel(
      id: 'alloc-1',
      clientUuid: 'alloc-1',
      paymentId: 'pay-1',
      studentChargeId: 'charge-1',
      feeTariffId: '1d763648-70e0-4272-8ca1-224db48adfd1',
      feeCode: 'EXAMINATION',
      studentChargeLabel: 'Organisation matériel examens — 2/3',
      amountInCents: 500000,
      currency: 'CDF',
    ).toPullPatch();

    expect(patch.containsKey('fee_tariff_id'), isFalse);
  });
}
