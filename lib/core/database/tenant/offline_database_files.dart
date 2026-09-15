import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/database/database_key_service.dart';
import 'package:school_app_flutter/core/database/offline_database_opener.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/database/tenant/legacy_database_split.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';

/// Les fichiers de base du poste (MULTI_ECOLE_PLAN.md §10.2-10.3) : où ils
/// vivent, sous quelle clé, et comment la base héritée devient celle d'une
/// école.
class OfflineDatabaseFiles {
  /// Répertoire des bases (`getDatabasesPath()` en production).
  final String directory;
  final DatabaseKeyService _keys;
  final OfflineDatabaseOpener _open;
  late final LegacyDatabaseSplit _split = LegacyDatabaseSplit(
    legacyPath: legacyPath,
    keys: _keys,
    open: _open,
  );

  OfflineDatabaseFiles({
    required this.directory,
    required DatabaseKeyService keys,
    required OfflineDatabaseOpener open,
  }) : _keys = keys,
       _open = open;

  static final RegExp _schoolIdPattern = RegExp(r'^[A-Za-z0-9-]{1,64}$');

  String get devicePath => p.join(directory, AppConstants.offlineDeviceDbName);

  String get legacyPath => p.join(directory, AppConstants.offlineDbName);

  /// Chemin du fichier de [schoolId].
  ///
  /// L'identifiant devient un nom de fichier : ce qui n'a pas la forme d'un
  /// identifiant est REFUSÉ plutôt que nettoyé. Deux écoles nettoyées vers le
  /// même nom partageraient un fichier — exactement ce que l'éclatement existe
  /// à empêcher.
  String schoolPath(String schoolId) {
    final name = '${AppConstants.offlineSchoolDbPrefix}$schoolId.db';
    if (!_schoolIdPattern.hasMatch(schoolId) ||
        name == AppConstants.offlineDbName) {
      throw ArgumentError.value(
        schoolId,
        'schoolId',
        'inutilisable comme nom de fichier de base',
      );
    }
    return p.join(directory, name);
  }

  /// Ouvre `device.db` — le crée au besoin — puis éclate la base héritée si
  /// elle attend de l'être.
  ///
  /// Un éclatement qui échoue ne fait pas échouer le démarrage : il est retenté
  /// à l'ouverture de la première école, qui, elle, refuse de s'ouvrir tant
  /// qu'il n'a pas abouti.
  Future<Database> openDevice() async {
    final device = await _open(
      devicePath,
      key: await _keys.getOrCreateDeviceKey(),
      version: AppConstants.offlineDbSchemaVersion,
      onCreate: (db, _) => createOfflineSchema(db, buildDeviceSchema()),
      onUpgrade: (db, oldVersion, newVersion) =>
          migrateDeviceDatabase(db, oldVersion, newVersion: newVersion),
    );
    try {
      await _split.runIfPending(device);
    } catch (_) {
      // Retenté à l'ouverture de la première école — cf. [openSchool].
    }
    return device;
  }

  /// Ouvre le fichier de [schoolId] : le sien s'il existe, sinon la base
  /// héritée si elle lui revient, sinon un fichier neuf.
  Future<Database> openSchool(
    String schoolId, {
    required Database device,
  }) async {
    final path = schoolPath(schoolId);
    if (!await File(path).exists()) {
      // Retenté ici, et SANS filet : créer un fichier neuf pendant que la base
      // héritée attend son éclatement l'orphelinerait. Son école aurait déjà
      // un fichier, et l'adoption n'aurait plus jamais lieu — avec, dedans, les
      // écritures qui n'étaient pas encore parties.
      await _split.runIfPending(device);
      await _adoptLegacyIfOwnedBy(schoolId, device, path);
    }
    return _open(
      path,
      key: await _keys.getOrCreateSchoolKey(schoolId),
      version: AppConstants.offlineDbSchemaVersion,
      onCreate: (db, _) => createOfflineSchema(db, buildTenantSchema()),
      onUpgrade: (db, oldVersion, newVersion) =>
          migrateTenantDatabase(db, oldVersion, newVersion: newVersion),
    );
  }

  /// Fait de la base héritée le fichier de [schoolId], si elle lui revient.
  ///
  /// Dans cet ordre, pour qu'une coupure à n'importe quel point se reprenne :
  /// la clé d'abord (le fichier renommé doit trouver la sienne), le fichier
  /// ensuite, la note enfin. Le palier v49 retire ensuite du fichier les tables
  /// passées à l'appareil, à sa première ouverture.
  Future<void> _adoptLegacyIfOwnedBy(
    String schoolId,
    Database device,
    String target,
  ) async {
    if (await readDeviceMeta(device, kLegacyStateKey) != kLegacyStateSplit) {
      return;
    }
    final legacy = File(legacyPath);
    if (!await legacy.exists()) {
      // Renommée par une adoption coupée avant sa note : le fichier est déjà
      // là où il devait aller, seule la note manquait. Rattrapée quelle que
      // soit l'école qui passe ici — celle qui a adopté ne repasse plus par
      // cette branche, son fichier existe.
      await writeDeviceMeta(device, kLegacyStateKey, kLegacyStateAdopted);
      return;
    }
    final owner = await readDeviceMeta(device, kLegacyOwnerKey);
    if (owner != null && owner != schoolId) return;

    await _keys.adoptLegacyKey(schoolId);
    await legacy.rename(target);
    // Un journal laissé derrière rattacherait ses pages à un fichier qui n'est
    // plus là. L'éclatement a ouvert puis fermé la base : il n'en reste
    // normalement aucun.
    for (final suffix in const ['-journal', '-wal', '-shm']) {
      final companion = File('$legacyPath$suffix');
      if (await companion.exists()) await companion.rename('$target$suffix');
    }
    await device.transaction((txn) async {
      await writeDeviceMeta(txn, kLegacyOwnerKey, schoolId);
      await writeDeviceMeta(txn, kLegacyStateKey, kLegacyStateAdopted);
    });
    try {
      await _keys.forgetLegacyKey();
    } catch (_) {
      // Rattrapé au démarrage suivant.
    }
  }
}
