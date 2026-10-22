import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Le dossier temporaire des pièces téléchargées à la demande : certificats
/// médicaux joints aux justifications d'absence, copies déposées par les
/// parents. Des documents d'élèves mineurs, donc **jamais de cache durable** :
/// ils vivent le temps de la session et la déconnexion les efface
/// ([purge]).
///
/// La clé est l'empreinte `sha256` de la pièce : deux lignes qui portent la
/// même pièce la partagent, et une pièce remplacée par le parent change de
/// clé d'elle-même.
///
/// Hors du web, les octets vont dans `<tmp>/attachments`. Sur le web, il n'y a
/// pas de système de fichiers : ils restent en mémoire, ce qui revient au même
/// pour une session.
///
/// **Best-effort de bout en bout** : un échec d'entrée-sortie rend « pas en
/// cache », jamais une erreur. Le pire est un téléchargement de plus.
class EphemeralAttachmentCache {
  static const String _directoryName = 'attachments';

  final Future<Directory> Function() _temporaryDirectory;
  final bool _inMemory;
  final Map<String, Uint8List> _memory = {};

  EphemeralAttachmentCache({
    Future<Directory> Function()? temporaryDirectory,
    bool? inMemory,
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _inMemory = inMemory ?? kIsWeb;

  /// Les octets de [sha256], `null` s'ils ne sont pas là.
  Future<Uint8List?> read(String sha256) async {
    if (_inMemory) return _memory[sha256];
    try {
      final file = await _fileOf(sha256);
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  Future<bool> contains(String sha256) async {
    if (_inMemory) return _memory.containsKey(sha256);
    try {
      return await (await _fileOf(sha256)).exists();
    } catch (_) {
      return false;
    }
  }

  Future<void> write(String sha256, Uint8List bytes) async {
    if (_inMemory) {
      _memory[sha256] = bytes;
      return;
    }
    try {
      final file = await _fileOf(sha256);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {
      // Pas de cache : la pièce se retéléchargera.
    }
  }

  /// Efface tout. Ne lève jamais : une déconnexion doit aboutir même si le
  /// dossier résiste.
  Future<void> purge() async {
    _memory.clear();
    if (_inMemory) return;
    try {
      final directory = Directory(
        p.join((await _temporaryDirectory()).path, _directoryName),
      );
      if (await directory.exists()) await directory.delete(recursive: true);
    } catch (_) {
      // Fichier résiduel plutôt que session impossible à fermer.
    }
  }

  Future<File> _fileOf(String sha256) async {
    // L'empreinte vient du serveur : on n'en garde que des caractères sûrs
    // pour un nom de fichier, jamais un chemin.
    final safe = sha256.replaceAll(RegExp('[^A-Za-z0-9]'), '');
    final root = (await _temporaryDirectory()).path;
    return File(p.join(root, _directoryName, safe));
  }
}
