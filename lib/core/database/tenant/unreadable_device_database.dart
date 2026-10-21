import 'package:sqflite_common/sqlite_api.dart';

/// Code SQLite d'un fichier qui ne se déchiffre pas : `SQLITE_NOTADB`.
const int _sqliteNotADatabase = 26;

/// Vrai si [error] est le refus d'une base chiffrée sous une AUTRE clé.
///
/// SQLCipher comme SQLite3MultipleCiphers ne savent pas distinguer une
/// mauvaise clé d'un fichier corrompu : la première page ne se déchiffre pas,
/// et le moteur répond « file is not a database ». En pratique, c'est la clé
/// du secure storage qui a disparu (trousseau vidé, profil restauré) — une
/// clé neuve a été générée, qui n'ouvre pas le fichier existant.
bool isUnreadableDatabaseError(Object error) =>
    error is DatabaseException &&
    (error.getResultCode() == _sqliteNotADatabase ||
        error.toString().contains('file is not a database'));

/// `device.db` existe mais ne s'ouvre pas sous la clé du secure storage.
///
/// Levée au démarrage, AVANT toute interface : l'application ne peut ni
/// connecter personne ni lire une école. C'est à l'utilisateur de trancher —
/// réessayer (un trousseau verrouillé se déverrouille) ou effacer les données
/// locales, ce qui perd les écritures qui n'étaient pas encore parties.
class UnreadableDeviceDatabaseException implements Exception {
  /// L'erreur du moteur, gardée pour le journal.
  final Object cause;

  /// Écarte les fichiers que plus aucune clé n'ouvre — cf.
  /// `OfflineDatabaseFiles.discardUnreadableFiles`.
  final Future<void> Function() discardUnreadableFiles;

  const UnreadableDeviceDatabaseException({
    required this.cause,
    required this.discardUnreadableFiles,
  });

  @override
  String toString() => 'UnreadableDeviceDatabaseException: $cause';
}
