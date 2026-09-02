import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/fees/local/fee_code_section_dao.dart';
import 'package:school_app_flutter/core/fees/local/fee_code_section_local_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v44 — `ref_fee_code_sections` : le titre que l'école donne à
/// chaque nature de frais, lisible hors ligne (GF-0).
///
/// Palier de création pure. Ce qu'il faut prouver tient en trois points :
///
///  1. **La table naît, et elle est utilisable** — pas seulement présente : le
///     DAO qui la sert doit pouvoir écrire et relire derrière la migration.
///  2. **Rien d'autre n'est touché.** Un cache de titres qui emporterait une
///     ligne de caisse au passage serait un défaut d'argent pour un gain
///     d'affichage.
///  3. **Le palier est rejouable.** Une base déjà en v44 le retraverse sans
///     perdre ce qu'elle contient — c'est le cas d'une base de terrain qui
///     remonte deux paliers d'un coup.
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

  Future<void> migrateFrom(int oldVersion) => migrateOfflineDatabase(
    db,
    oldVersion,
    buildOfflineSchema(),
    newVersion: 44,
  );

  Future<bool> hasTable(String name) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
      [name],
    );
    return rows.isNotEmpty;
  }

  test('une base v43 reçoit la table, et elle sert vraiment', () async {
    expect(await hasTable('ref_fee_code_sections'), isFalse);

    await migrateFrom(43);

    expect(await hasTable('ref_fee_code_sections'), isTrue);

    // « La table existe » et « la table sert » ne sont pas la même chose : on
    // écrit et on relit par le DAO réel, colonnes comprises.
    final dao = FeeCodeSectionDao(db);
    await dao.replaceForSchool([
      const FeeCodeSectionLocalModel(
        schoolId: 'school-A',
        code: 'TUITION',
        label: 'Frais scolaires',
        sortOrder: 3,
      ),
    ], schoolId: 'school-A');

    expect(await dao.titlesForSchool('school-A'), {
      'TUITION': 'Frais scolaires',
    });
  });

  test(
    'la table naît VIDE : rien à rattraper, et le repli est stable',
    () async {
      await migrateFrom(43);

      expect(await db.query('ref_fee_code_sections'), isEmpty);
      expect(
        await FeeCodeSectionDao(db).titlesForSchool('school-A'),
        isEmpty,
        reason:
            'Un cache vide nomme par la nature localisée, et dit toujours la '
            'même chose — c\'est précisément ce que le cache mémoire du '
            'provisioning ne faisait pas.',
      );
    },
  );

  test('le palier ne touche à rien d\'autre', () async {
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        client_uuid TEXT NOT NULL,
        student_id TEXT NOT NULL,
        paid_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC'
      )
    ''');
    await db.insert('payments', {
      'id': 'p-1',
      'client_uuid': 'c-1',
      'student_id': 's-1',
      'paid_at': '2026-09-01T10:00:00Z',
      'sync_status': 'SYNCED',
    });

    await migrateFrom(43);

    expect(await db.query('payments'), hasLength(1));
  });

  test('rejouable sur une base déjà en v44, sans rien perdre', () async {
    await migrateFrom(43);
    final dao = FeeCodeSectionDao(db);
    await dao.replaceForSchool([
      const FeeCodeSectionLocalModel(
        schoolId: 'school-A',
        code: 'CANTEEN',
        label: 'Cantine',
      ),
    ], schoolId: 'school-A');

    await migrateFrom(44);

    expect(await dao.titlesForSchool('school-A'), {'CANTEEN': 'Cantine'});
  });
}
