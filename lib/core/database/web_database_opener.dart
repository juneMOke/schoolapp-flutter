import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// L'ouvreur du navigateur : SQLite en WASM, persisté dans IndexedDB, servi
/// par un SharedWorker — tous les onglets partagent la même connexion.
///
/// ⚠️ [key] est IGNORÉE : la base du navigateur n'est pas chiffrée. Une clé
/// rangée dans le même navigateur que la base ne protégerait rien. Le web est
/// en ligne seulement : la base n'y est qu'un cache du serveur, plus l'outbox
/// le temps de son envoi.
Future<Database> openWebDatabase(
  String path, {
  required String key,
  required int version,
  required OnDatabaseCreateFn onCreate,
  required OnDatabaseVersionChangeFn onUpgrade,
}) => databaseFactoryFfiWeb.openDatabase(
  path,
  options: OpenDatabaseOptions(
    version: version,
    onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    onCreate: onCreate,
    onUpgrade: onUpgrade,
  ),
);

/// Existence d'une base du navigateur : `File.exists` n'a pas cours ici.
Future<bool> webDatabaseExists(String path) =>
    databaseFactoryFfiWeb.databaseExists(path);

/// « Répertoire » des bases du navigateur : un simple préfixe de nom dans
/// IndexedDB, un par environnement (même raison que sur le poste de bureau).
const String webDatabasesDirectory = 'eteelo/$_appEnvironment';

const String _appEnvironment = String.fromEnvironment(
  AppConstants.appEnvironmentDefineKey,
  defaultValue: AppConstants.defaultAppEnvironment,
);
