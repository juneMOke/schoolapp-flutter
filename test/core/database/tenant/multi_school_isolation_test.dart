import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/database_key_service.dart';
import 'package:school_app_flutter/core/database/tenant/offline_database_files.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_database.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_scope.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_session.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_seed_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/parent_search_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_payer_directory_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

/// La contre-épreuve (MULTI_ECOLE_PLAN.md §7 lot 5) : DEUX écoles dans une même
/// suite, A → B → A, à travers le câblage de production — un proxy, de vrais
/// fichiers, et des DAO qui ne savent rien de l'école.
///
/// C'est le seul test qui aurait attrapé D1, D2, D4, D5 et D6 : toutes les
/// suites existantes montent une seule école, et un `WHERE` manquant n'y lève
/// rien.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory dir;
  late List<Database> opened;
  late TenantDatabase tenant;
  late TenantSession session;

  // Câblés comme en production : sur le proxy, jamais sur un fichier.
  late SyncMetaDao syncMeta;
  late EnrollmentSeedDao seed;
  late EnrollmentReferentialDao referential;
  late ParentSearchDao parents;
  late FinancePayerDirectoryDao payers;
  late OutboxDao outbox;

  Future<Database> ffiOpen(
    String path, {
    required String key,
    required int version,
    required OnDatabaseCreateFn onCreate,
    required OnDatabaseVersionChangeFn onUpgrade,
  }) async {
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
        singleInstance: false,
      ),
    );
    opened.add(db);
    return db;
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('multi_ecole_isolation_');
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    opened = <Database>[];
    final files = OfflineDatabaseFiles(
      directory: dir.path,
      keys: const DatabaseKeyService(FlutterSecureStorage(), Uuid()),
      open: ffiOpen,
    );
    final device = await files.openDevice();
    tenant = TenantDatabase();
    session = TenantSession(tenant: tenant, files: files, device: device);
    syncMeta = SyncMetaDao(tenant);
    seed = EnrollmentSeedDao(tenant);
    referential = EnrollmentReferentialDao(tenant);
    parents = ParentSearchDao(tenant);
    payers = FinancePayerDirectoryDao(tenant);
    outbox = OutboxDao(tenant);
  });

  tearDown(() async {
    for (final db in opened) {
      if (db.isOpen) await db.close();
    }
    await dir.delete(recursive: true);
  });

  /// Ce qu'un premier cycle laisse dans le fichier d'une école : son année
  /// courante, son en-tête, un tuteur, un payeur, un curseur, une écriture en
  /// attente.
  Future<void> seedSchool(
    String school, {
    required String year,
    required String family,
    required String cursor,
  }) async {
    await tenant.insert('ref_academic_years', {
      'id': year,
      'name': 'Année $year',
      'school_id': school,
      'is_current': 1,
    });
    await tenant.insert('ref_school', {'id': school, 'name': 'École $school'});
    await tenant.insert('parents', {
      'id': 'parent-$school',
      'first_name': 'Joseph',
      'last_name': family,
    });
    await tenant.insert('payments', {
      'id': 'pay-$school',
      'client_uuid': 'pay-$school',
      'student_id': 'eleve-$school',
      'paid_at': '2026-09-01T08:00:00Z',
      'payer_last_name': family,
      'payer_first_name': 'Joseph',
      'sync_status': 'SYNCED',
      'updated_at': 0,
    });
    await syncMeta.setCursor('enrollments', cursor: cursor, syncedAt: 1);
    await outbox.enqueue(
      OutboxEntry(
        id: 'o-$school',
        aggregateType: 'PAYMENT',
        aggregateId: 'pay-$school',
        operation: OutboxOperation.create,
        payload: jsonEncode({'authorId': 'uid-$school'}),
        createdAt: 1,
      ),
    );
  }

  test('A → B → A : rien de A ne se lit chez B, et A retrouve tout', () async {
    await session.attach('school-a');
    await seedSchool(
      'school-a',
      year: 'annee-a',
      family: 'KABILA',
      cursor: 'curseur-a',
    );

    await session.attach('school-b');

    // D1 — le curseur de A ne se rejoue pas chez B : B tire depuis le début.
    expect(await syncMeta.getCursor('enrollments'), isNull);
    // D2 — l'année courante résolue sans école n'est pas celle de A.
    expect(await seed.findCurrentAcademicYearId(), isNull);
    // D4 — l'en-tête des tickets ne porte pas l'école de A.
    expect(await tenant.query('ref_school'), isEmpty);
    // D5 — les tuteurs de A ne sont pas proposés au guichet de B.
    expect(await parents.search(lastName: 'KABILA'), isEmpty);
    // D6 — l'annuaire des payeurs non plus.
    expect(await payers.searchPayers(lastName: 'KABILA'), isEmpty);
    // La file d'écriture de B n'est pas celle de A.
    expect(await outbox.pendingCount(), 0);

    await seedSchool(
      'school-b',
      year: 'annee-b',
      family: 'LUMUMBA',
      cursor: 'curseur-b',
    );

    await session.attach('school-a');

    expect(await syncMeta.getCursor('enrollments'), 'curseur-a');
    expect(await seed.findCurrentAcademicYearId(), 'annee-a');
    expect(await referential.findCurrentAcademicYearId('school-a'), 'annee-a');
    expect(await parents.search(lastName: 'KABILA'), hasLength(1));
    expect(await parents.search(lastName: 'LUMUMBA'), isEmpty);
    expect(await payers.searchPayers(lastName: 'KABILA'), isNotEmpty);
    expect(await payers.searchPayers(lastName: 'LUMUMBA'), isEmpty);
    expect(await outbox.pendingCount(), 1);
  });

  test('une session fermée ne détruit rien : sans école, aucun accès ; au '
      'retour, tout est là', () async {
    await session.attach('school-a');
    await seedSchool(
      'school-a',
      year: 'annee-a',
      family: 'KABILA',
      cursor: 'curseur-a',
    );

    await session.detach();

    await expectLater(
      syncMeta.getCursor('enrollments'),
      throwsA(isA<NoTenantAttachedException>()),
    );

    await session.attach('school-a');

    expect(await syncMeta.getCursor('enrollments'), 'curseur-a');
    expect(await outbox.pendingCount(), 1);
  });
}
