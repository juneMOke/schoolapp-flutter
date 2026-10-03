import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// L'ouvreur du poste de bureau (Windows, Linux) : ffi sur
/// SQLite3MultipleCiphers, clés étrangères actives.
///
/// Même contrat que `openSqlCipherDatabase` : même clé, même `onCreate`, même
/// `onUpgrade`. Seul le format du fichier diffère (ChaCha20 de
/// SQLite3MultipleCiphers et non AES de SQLCipher) — sans conséquence, aucun
/// fichier ne voyage d'une tablette à un poste.
///
/// ⚠️ La clé est posée DANS `onConfigure`, premier rappel de sqflite après
/// l'ouverture et avant la lecture de `user_version` : SQLite3MultipleCiphers
/// exige qu'elle précède toute lecture de page.
Future<Database> openDesktopCipherDatabase(
  String path, {
  required String key,
  required int version,
  required OnDatabaseCreateFn onCreate,
  required OnDatabaseVersionChangeFn onUpgrade,
}) {
  sqfliteFfiInit();
  return databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: version,
      onConfigure: (db) async {
        await db.execute("PRAGMA key = '${key.replaceAll("'", "''")}'");
        await _ensureCipherBuild(db);
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    ),
  );
}

/// Refuse d'ouvrir sur un SQLite ordinaire.
///
/// Si le hook de `package:sqlite3` n'a pas embarqué SQLite3MultipleCiphers
/// (`hooks.user_defines` du pubspec perdu), `PRAGMA key` est ignoré SANS
/// erreur et la base — grand-livre compris — s'écrirait en clair. La fonction
/// `sqlite3mc_version()` n'existe que dans le build chiffrant.
///
/// ⚠️ Seul `no such function` est requalifié. Préparer la requête lit le
/// schéma : une MAUVAISE clé lève ici `file is not a database`, qui doit
/// remonter tel quel — le confondre avec un build manquant ferait chercher la
/// mauvaise panne.
Future<void> _ensureCipherBuild(Database db) async {
  try {
    await db.rawQuery('SELECT sqlite3mc_version()');
  } on DatabaseException catch (error) {
    if (!error.toString().contains('no such function')) rethrow;
    throw StateError(
      'SQLite3MultipleCiphers absent : base non chiffrable ($error)',
    );
  }
}

/// Répertoire des bases du poste : le dossier de support de l'application
/// (`%APPDATA%` sous Windows, `~/.local/share` sous Linux), un sous-dossier
/// par environnement.
///
/// Sur la tablette, chaque flavor est une application distincte, aux données
/// distinctes. Le poste n'a qu'un exécutable : sans ce sous-dossier, une
/// installation de staging relirait la base de la production — ses écoles,
/// ses versements — et la pousserait vers un autre serveur.
///
/// ⚠️ Jamais `databaseFactoryFfi.getDatabasesPath()` : il rend un dossier
/// RELATIF au répertoire courant (`.dart_tool/…`), qui change selon la façon
/// dont l'exécutable est lancé.
Future<String> desktopDatabasesDirectory() async => p.join(
  (await getApplicationSupportDirectory()).path,
  'databases',
  const String.fromEnvironment(
    AppConstants.appEnvironmentDefineKey,
    defaultValue: AppConstants.defaultAppEnvironment,
  ),
);
