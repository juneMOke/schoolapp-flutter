import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/desktop_database_opener.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// L'ouvreur du poste de bureau, sur de VRAIS fichiers : la seule preuve que
/// la base ne s'écrit pas en clair est l'en-tête du fichier lui-même.
void main() {
  late Directory dir;
  late String path;

  const key =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('eteelo_desktop_db');
    path = '${dir.path}/school.db';
  });

  tearDown(() => dir.delete(recursive: true));

  Future<Database> open(String withKey, {int version = 1}) =>
      openDesktopCipherDatabase(
        path,
        key: withKey,
        version: version,
        onCreate: (db, _) =>
            db.execute('CREATE TABLE ledger (id TEXT PRIMARY KEY, cents INT)'),
        onUpgrade: (_, _, _) async {},
      );

  test('le fichier écrit n\'est pas une base SQLite en clair', () async {
    final db = await open(key);
    await db.insert('ledger', {'id': 'p-1', 'cents': 125000});
    await db.close();

    final header = String.fromCharCodes(File(path).readAsBytesSync().take(15));
    expect(header, isNot('SQLite format 3'));
  });

  test('la même clé relit les données et la version du schéma', () async {
    final first = await open(key);
    await first.insert('ledger', {'id': 'p-1', 'cents': 125000});
    await first.close();

    final again = await open(key);
    expect(await again.getVersion(), 1);
    expect(await again.query('ledger'), [
      {'id': 'p-1', 'cents': 125000},
    ]);
    await again.close();
  });

  test('une autre clé ne lit rien', () async {
    final first = await open(key);
    await first.insert('ledger', {'id': 'p-1', 'cents': 125000});
    await first.close();

    await expectLater(open('f' * 64), throwsA(isA<DatabaseException>()));
  });

  test('les clés étrangères sont actives', () async {
    final db = await open(key);
    final rows = await db.rawQuery('PRAGMA foreign_keys');
    expect(rows.single.values.single, 1);
    await db.close();
  });
}
