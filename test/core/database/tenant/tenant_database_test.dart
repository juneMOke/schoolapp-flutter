import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_database.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_scope.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _openSchoolFile() async {
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  await db.execute('CREATE TABLE t (id TEXT PRIMARY KEY)');
  return db;
}

Future<List<String>> _ids(Database db) async => (await db.query(
  't',
  orderBy: 'id',
)).map((r) => r['id']! as String).toList();

void main() {
  sqfliteFfiInit();

  late Database fileA;
  late Database fileB;
  late TenantDatabase tenant;

  setUp(() async {
    fileA = await _openSchoolFile();
    fileB = await _openSchoolFile();
    tenant = TenantDatabase();
  });

  tearDown(() async {
    await fileA.close();
    await fileB.close();
  });

  group('sans école attachée', () {
    test('toute lecture lève un échec typé, jamais un vide', () async {
      expect(tenant.isAttached, isFalse);
      await expectLater(
        tenant.query('t'),
        throwsA(isA<NoTenantAttachedException>()),
      );
      await expectLater(
        tenant.insert('t', {'id': 'x'}),
        throwsA(isA<NoTenantAttachedException>()),
      );
      await expectLater(
        tenant.transaction((txn) async {}),
        throwsA(isA<NoTenantAttachedException>()),
      );
    });

    test('après détachement, même règle', () async {
      tenant.attach('school-a', fileA);
      tenant.detach();

      expect(tenant.schoolId, isNull);
      await expectLater(
        tenant.query('t'),
        throwsA(isA<NoTenantAttachedException>()),
      );
    });
  });

  group('délégation', () {
    test('écrit et lit dans le fichier attaché', () async {
      tenant.attach('school-a', fileA);

      await tenant.insert('t', {'id': 'a1'});

      expect(await _ids(fileA), ['a1']);
      expect(await _ids(fileB), isEmpty);
      expect(tenant.schoolId, 'school-a');
    });

    test('la bascule change de fichier : B ne voit rien de A', () async {
      tenant.attach('school-a', fileA);
      await tenant.insert('t', {'id': 'a1'});

      tenant.attach('school-b', fileB);
      await tenant.insert('t', {'id': 'b1'});

      expect((await tenant.query('t')).single['id'], 'b1');
      expect(await _ids(fileA), ['a1']);
    });

    test(
      'une transaction reçoit le fichier, et `database` rend le proxy',
      () async {
        tenant.attach('school-a', fileA);

        await tenant.transaction((txn) async {
          await txn.insert('t', {'id': 'a1'});
        });

        expect(await _ids(fileA), ['a1']);
        expect(identical(tenant.database, tenant), isTrue);
      },
    );

    test('le proxy ne se ferme pas : la session détache', () {
      tenant.attach('school-a', fileA);

      expect(() => tenant.close(), throwsUnsupportedError);
      expect(fileA.isOpen, isTrue);
    });
  });

  group('travail lié à une école (run)', () {
    test('sans bascule, un travail lié écrit normalement', () async {
      tenant.attach('school-a', fileA);

      await tenant.run(() async {
        expect(tenant.isStale, isFalse);
        await tenant.insert('t', {'id': 'a1'});
      });

      expect(await _ids(fileA), ['a1']);
    });

    test('la réponse de A arrivée après la bascule vers B ne s écrit NULLE '
        'PART', () async {
      tenant.attach('school-a', fileA);
      final network = Completer<void>();

      final pull = tenant.run(() async {
        await network.future; // la requête de A est en vol
        expect(tenant.isStale, isTrue);
        await tenant.insert('t', {'id': 'page-de-a'});
      });

      // A se déconnecte, B se connecte, puis la réponse arrive.
      tenant.detach();
      tenant.attach('school-b', fileB);
      network.complete();

      await expectLater(pull, throwsA(isA<StaleTenantException>()));
      expect(await _ids(fileB), isEmpty);
      expect(await _ids(fileA), isEmpty);
    });

    test('se reconnecter à la MÊME école périme aussi le travail : ses jetons '
        'ne sont plus ceux de la session', () async {
      tenant.attach('school-a', fileA);
      final network = Completer<void>();

      final pull = tenant.run(() async {
        await network.future;
        await tenant.insert('t', {'id': 'x'});
      });

      tenant.detach();
      tenant.attach('school-a', fileA);
      network.complete();

      await expectLater(pull, throwsA(isA<StaleTenantException>()));
      expect(await _ids(fileA), isEmpty);
    });

    test('hors de toute portée, un appel n est jamais « périmé »', () async {
      tenant.attach('school-a', fileA);
      tenant.attach('school-b', fileB);

      expect(tenant.isStale, isFalse);
      await tenant.insert('t', {'id': 'b1'});
      expect(await _ids(fileB), ['b1']);
    });

    test('une transaction commencée avant la bascule se termine sur SON '
        'fichier', () async {
      tenant.attach('school-a', fileA);
      final inside = Completer<void>();
      final release = Completer<void>();

      final write = tenant.transaction((txn) async {
        inside.complete();
        await release.future;
        await txn.insert('t', {'id': 'a1'});
      });

      await inside.future;
      tenant.attach('school-b', fileB);
      release.complete();
      await write;

      expect(await _ids(fileA), ['a1']);
      expect(await _ids(fileB), isEmpty);
    });
  });

  test('UnboundTenantScope ne lie rien', () async {
    const scope = UnboundTenantScope();

    final value = await scope.run(() async => 42);

    expect(value, 42);
    expect(scope.isStale, isFalse);
  });
}
