import 'dart:typed_data';

import 'package:school_app_flutter/core/storage/encrypted_blob/blob_files.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les octets scellés d'un magasin, dans le navigateur : une table d'une base
/// IndexedDB dédiée, une ligne par pièce et par état.
///
/// Les octets restent chiffrés par `EncryptedBlobStore` avant d'arriver ici.
/// Ce n'est pas une protection forte — la clé vit dans le même navigateur —
/// mais c'est le même format que sur la tablette, sans branche dans le magasin.
///
/// ⚠️ Persistant à dessein : les justificatifs RH y attendent leur envoi par
/// l'outbox, conservée elle aussi dans le navigateur.
class WebBlobFiles implements BlobFiles {
  static const String _table = 'blob_files';
  static const String _pending = 'pending';
  static const String _sealed = 'sealed';

  /// Le magasin servi (`EncryptedBlobStore.directoryName`) : plusieurs
  /// magasins partagent la même base.
  final String name;
  final DatabaseFactory _factory;
  final String _path;
  Future<Database>? _db;

  WebBlobFiles({
    required this.name,
    required DatabaseFactory factory,
    required String path,
  }) : _factory = factory,
       _path = path;

  Future<Database> _open() => _db ??= _factory.openDatabase(
    _path,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE $_table (store TEXT NOT NULL, id TEXT NOT NULL, '
        'state TEXT NOT NULL, bytes BLOB NOT NULL, '
        'PRIMARY KEY (store, id, state))',
      ),
    ),
  );

  @override
  Future<void> writePending(String id, Uint8List sealed) async {
    final db = await _open();
    await db.insert(_table, {
      'store': name,
      'id': id,
      'state': _pending,
      'bytes': sealed,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<bool> commit(String id) async {
    final db = await _open();
    return db.transaction((txn) async {
      final rows = await txn.query(
        _table,
        columns: ['bytes'],
        where: 'store = ? AND id = ? AND state = ?',
        whereArgs: [name, id, _pending],
      );
      if (rows.isEmpty) return false;
      await txn.insert(_table, {
        'store': name,
        'id': id,
        'state': _sealed,
        'bytes': rows.single['bytes'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete(
        _table,
        where: 'store = ? AND id = ? AND state = ?',
        whereArgs: [name, id, _pending],
      );
      return true;
    });
  }

  @override
  Future<void> discardPending(String id) => _deleteState(id, _pending);

  @override
  Future<bool> sealedExists(String id) async =>
      (await _sealedRow(id, columns: ['id'])) != null;

  @override
  Future<Uint8List?> readSealed(String id) async {
    final row = await _sealedRow(id, columns: ['bytes']);
    return row == null ? null : row['bytes']! as Uint8List;
  }

  @override
  Future<void> delete(String id) async {
    final db = await _open();
    await db.delete(
      _table,
      where: 'store = ? AND id = ?',
      whereArgs: [name, id],
    );
  }

  @override
  Future<void> deleteAll() async {
    try {
      final db = await _open();
      await db.delete(_table, where: 'store = ?', whereArgs: [name]);
    } catch (_) {
      // Même contrat que le disque : l'effacement ne lève jamais.
    }
  }

  @override
  Future<int> reclaimOrphans({required Set<String> indexedIds}) async {
    try {
      final db = await _open();
      final rows = await db.query(
        _table,
        columns: ['id', 'state'],
        where: 'store = ?',
        whereArgs: [name],
      );
      var removed = 0;
      for (final row in rows) {
        final id = row['id']! as String;
        final state = row['state']! as String;
        if (state == _sealed && indexedIds.contains(id)) continue;
        await _deleteState(id, state);
        removed++;
      }
      return removed;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, Object?>?> _sealedRow(
    String id, {
    required List<String> columns,
  }) async {
    final db = await _open();
    final rows = await db.query(
      _table,
      columns: columns,
      where: 'store = ? AND id = ? AND state = ?',
      whereArgs: [name, id, _sealed],
    );
    return rows.isEmpty ? null : rows.single;
  }

  Future<void> _deleteState(String id, String state) async {
    final db = await _open();
    await db.delete(
      _table,
      where: 'store = ? AND id = ? AND state = ?',
      whereArgs: [name, id, state],
    );
  }
}
