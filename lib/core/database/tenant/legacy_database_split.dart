import 'dart:io';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/database_key_service.dart';
import 'package:school_app_flutter/core/database/offline_database_opener.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

/// Clé de `device_meta` : où en est la base héritée.
const String kLegacyStateKey = 'legacy.state';

/// Clé de `device_meta` : l'école qui l'adoptera (`NULL` : la première qui
/// ouvrira une session).
const String kLegacyOwnerKey = 'legacy.owner_school_id';

/// La base héritée est éclatée : l'appareil a sa copie, le fichier attend son
/// école.
const String kLegacyStateSplit = 'split';

/// La base héritée est adoptée : elle est devenue le fichier d'une école.
const String kLegacyStateAdopted = 'adopted';

/// Ce qui passe de la base héritée à l'appareil, dans cet ordre : la session
/// référence le compte, et les clés étrangères sont actives.
const List<String> _deviceTablesInCopyOrder = [
  'auth_local_user',
  'auth_local_session',
  'editique_cache_entries',
];

/// Les curseurs du catalogue éditique, qui suivent son index.
const String _editiqueCursorsWhere =
    "substr(resource, 1, 18) = 'editique_documents'";

Future<String?> readDeviceMeta(DatabaseExecutor db, String key) async {
  final rows = await db.query(
    'device_meta',
    columns: ['value'],
    where: 'key = ?',
    whereArgs: [key],
    limit: 1,
  );
  return rows.isEmpty ? null : rows.first['value'] as String?;
}

Future<void> writeDeviceMeta(DatabaseExecutor db, String key, String? value) =>
    db.insert('device_meta', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

/// Un compte vu sur la tablette, tel que la désignation le lit.
class LegacyAccount {
  final String userId;
  final String schoolId;
  final int lastServerSeenAt;

  const LegacyAccount({
    required this.userId,
    required this.schoolId,
    required this.lastServerSeenAt,
  });
}

/// Une écriture restée en file dans la base héritée.
class LegacyPendingWrite {
  final String payload;

  /// Colonne `outbox.school_id` : trois flux sur neuf l'estampillaient.
  final String? schoolId;

  const LegacyPendingWrite({required this.payload, this.schoolId});
}

/// L'école qui adoptera la base héritée, ou `null` : la première qui ouvrira
/// une session.
///
/// **L'argent d'abord.** Si des écritures attendent en file, seules leurs
/// écoles sont candidates : ces écritures ne partiront qu'avec un jeton de leur
/// auteur, donc depuis le fichier de son école — adoptée par une autre, la base
/// les garderait en attente pour toujours. Parmi les candidates, on prend
/// l'école de la session active, puis celle du compte vu le plus récemment.
///
/// Sur une tablette mono-école, c'est-à-dire tout le parc hors staging, les
/// trois règles désignent la même école.
String? designateLegacyOwner({
  required List<LegacyAccount> accounts,
  required String? sessionUserId,
  required List<LegacyPendingWrite> pending,
}) {
  final schoolOf = {for (final a in accounts) a.userId: a.schoolId};

  final pendingSchools = <String>{};
  for (final write in pending) {
    final explicit = write.schoolId;
    final school = (explicit != null && explicit.isNotEmpty)
        ? explicit
        : schoolOf[outboxAuthorUidOf(write.payload)];
    if (school != null) pendingSchools.add(school);
  }

  final candidates = pendingSchools.isNotEmpty
      ? pendingSchools
      : {for (final a in accounts) a.schoolId};
  if (candidates.isEmpty) return null;
  if (candidates.length == 1) return candidates.single;

  final sessionSchool = sessionUserId == null ? null : schoolOf[sessionUserId];
  if (sessionSchool != null && candidates.contains(sessionSchool)) {
    return sessionSchool;
  }
  final recent = accounts.where((a) => candidates.contains(a.schoolId)).toList()
    ..sort((a, b) => b.lastServerSeenAt.compareTo(a.lastServerSeenAt));
  if (recent.isNotEmpty) return recent.first.schoolId;
  return (candidates.toList()..sort()).first;
}

/// Éclate la base héritée (MULTI_ECOLE_PLAN.md §10.3, étape 1).
///
/// Recopie dans `device.db` ce qui appartient à l'appareil — comptes, session,
/// index éditique et ses curseurs — et désigne l'école qui adoptera le fichier.
/// La base héritée n'est jamais modifiée ici, hors sa montée à la v48 : un
/// éclatement qui échoue se rejoue tel quel.
class LegacyDatabaseSplit {
  final String legacyPath;
  final DatabaseKeyService _keys;
  final OfflineDatabaseOpener _open;

  const LegacyDatabaseSplit({
    required this.legacyPath,
    required DatabaseKeyService keys,
    required OfflineDatabaseOpener open,
  }) : _keys = keys,
       _open = open;

  /// Éclate la base héritée si elle attend de l'être.
  ///
  /// Sans effet si c'est déjà fait, s'il n'y a pas de base héritée, ou si sa
  /// clé a disparu : elle reste alors en place, jamais adoptée, jamais effacée.
  /// **Lève** si la base, lisible, n'a pas pu être éclatée : c'est à
  /// l'appelant de décider s'il peut continuer sans.
  Future<void> runIfPending(Database device) async {
    final state = await readDeviceMeta(device, kLegacyStateKey);
    if (state != null) {
      if (state == kLegacyStateAdopted) await _forgetAdoptedKey();
      return;
    }
    if (!await File(legacyPath).exists()) return;
    final key = await _keys.readLegacyKey();
    if (key == null) return;

    final legacy = await _open(
      legacyPath,
      key: key,
      version: AppConstants.legacyOfflineDbSchemaVersion,
      onCreate: (db, _) => createOfflineSchema(db, buildOfflineSchema()),
      onUpgrade: (db, oldVersion, newVersion) => migrateOfflineDatabase(
        db,
        oldVersion,
        buildOfflineSchema(),
        newVersion: newVersion,
      ),
    );
    try {
      await _copyToDevice(legacy, device);
    } finally {
      await legacy.close();
    }
  }

  Future<void> _copyToDevice(Database legacy, Database device) async {
    final owner = designateLegacyOwner(
      accounts: [
        for (final row in await legacy.query('auth_local_user'))
          LegacyAccount(
            userId: row['user_id']! as String,
            schoolId: row['school_id']! as String,
            lastServerSeenAt: row['last_server_seen_at']! as int,
          ),
      ],
      sessionUserId:
          (await legacy.query(
                'auth_local_session',
                where: 'id = 1',
                limit: 1,
              )).firstOrNull?['user_id']
              as String?,
      pending: [
        for (final row in await legacy.query(
          'outbox',
          columns: ['payload', 'school_id'],
          where: 'status IN (?, ?)',
          whereArgs: [
            OutboxStatus.pending.dbValue,
            OutboxStatus.syncError.dbValue,
          ],
        ))
          LegacyPendingWrite(
            payload: row['payload']! as String,
            schoolId: row['school_id'] as String?,
          ),
      ],
    );

    final rows = {
      for (final table in _deviceTablesInCopyOrder)
        table: await legacy.query(table),
    };
    final cursors = await legacy.query(
      'sync_meta',
      where: _editiqueCursorsWhere,
    );

    // UNE transaction : l'appareil a tout, ou rien — et alors l'état reste
    // absent, et l'éclatement se rejouera.
    await device.transaction((txn) async {
      for (final entry in rows.entries) {
        final columns = await _columnsOf(txn, entry.key);
        for (final row in entry.value) {
          // Une ligne déjà présente côté appareil gagne : elle ne peut venir
          // que d'un login PLUS RÉCENT que la base héritée.
          await txn.insert(entry.key, {
            for (final cell in row.entries)
              if (columns.contains(cell.key)) cell.key: cell.value,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
      for (final cursor in cursors) {
        await txn.insert(
          'sync_meta',
          cursor,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await writeDeviceMeta(txn, kLegacyOwnerKey, owner);
      await writeDeviceMeta(txn, kLegacyStateKey, kLegacyStateSplit);
    });
  }

  /// Colonnes de [table] côté appareil : une colonne que la base héritée porte
  /// et que l'appareil ne connaît plus ne doit pas faire échouer la copie.
  Future<Set<String>> _columnsOf(DatabaseExecutor db, String table) async => {
    for (final row in await db.rawQuery('PRAGMA table_info($table)'))
      row['name']! as String,
  };

  /// Une adoption coupée entre la note et l'oubli laisse la clé héritée : la
  /// même valeur vit déjà sous le nom de l'école.
  Future<void> _forgetAdoptedKey() async {
    try {
      if (await File(legacyPath).exists()) return;
      if (await _keys.readLegacyKey() == null) return;
      await _keys.forgetLegacyKey();
    } catch (_) {
      // Hygiène : sans conséquence sur le démarrage.
    }
  }
}
