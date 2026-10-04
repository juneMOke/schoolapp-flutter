import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_files.dart';

/// Le répertoire d'un `EncryptedBlobStore` et la façon d'y nommer les
/// fichiers : un fichier scellé (`<id>.enc`) et, le temps d'une écriture, un
/// fichier d'attente (`<id>.part`).
///
/// Ne chiffre rien et ne connaît aucune clé : il sait où sont les octets, pas
/// ce qu'ils disent. Aucune de ses opérations ne lève sur une panne
/// d'entrée-sortie, à l'exception de [ensure], dont l'échec interrompt une
/// écriture que l'appelant sait déjà rattraper.
class BlobDirectory implements BlobFiles {
  /// Suffixe d'un fichier complet, et d'une écriture en cours. Séparés parce
  /// qu'une écriture interrompue ne doit jamais être relue comme une pièce.
  static const String sealedSuffix = '.enc';
  static const String pendingSuffix = '.part';

  /// Un identifiant nomme un fichier : tout ce qui pourrait sortir du
  /// répertoire (`..`, `/`) ou heurter un système de fichiers est refusé.
  /// Les clés locales sont des UUID v4, cette forme les couvre entièrement.
  static final RegExp _safeId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  /// Sous-répertoire propre au magasin, sous le répertoire de base. Deux
  /// magasins ne partagent jamais le même : chacun efface le sien en bloc.
  final String name;

  /// Résout le répertoire de base. En production, le répertoire de
  /// **support** — privé à l'application, et non le cache, que le système peut
  /// vider sous nos pieds alors que l'index, lui, resterait.
  final Future<Directory> Function() _baseDirectory;

  BlobDirectory({
    required this.name,
    required Future<Directory> Function() baseDirectory,
  }) : _baseDirectory = baseDirectory;

  /// [id] peut-il nommer un fichier de ce répertoire ?
  static bool isSafeId(String id) => _safeId.hasMatch(id);

  /// Lève si [id] ne peut pas nommer un fichier : c'est une faute d'appelant.
  static void requireSafeId(String id) {
    if (isSafeId(id)) return;
    throw ArgumentError.value(
      id,
      'id',
      'Identifiant impropre à nommer un fichier : il désignerait un chemin '
          'hors du magasin',
    );
  }

  /// Le répertoire, **sans le créer** : le constater absent est une réponse en
  /// soi sur tous les chemins sauf l'écriture.
  Future<Directory> resolve() async =>
      Directory(p.join((await _baseDirectory()).path, name));

  /// Le répertoire, créé au besoin — pour écrire.
  Future<Directory> ensure() async {
    final dir = await resolve();
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Fichier scellé de [id] dans [dir].
  static File sealedFile(Directory dir, String id) =>
      File(p.join(dir.path, '$id$sealedSuffix'));

  /// Fichier d'attente de [id] dans [dir].
  static File pendingFile(Directory dir, String id) =>
      File(p.join(dir.path, '$id$pendingSuffix'));

  @override
  Future<void> writePending(String id, Uint8List sealed) async {
    final dir = await ensure();
    await pendingFile(dir, id).writeAsBytes(sealed, flush: true);
  }

  @override
  Future<bool> commit(String id) async {
    final dir = await resolve();
    final pending = pendingFile(dir, id);
    if (!await pending.exists()) return false;
    await pending.rename(sealedFile(dir, id).path);
    return true;
  }

  @override
  Future<void> discardPending(String id) async =>
      quietlyDelete(pendingFile(await resolve(), id));

  @override
  Future<bool> sealedExists(String id) async =>
      sealedFile(await resolve(), id).exists();

  @override
  Future<Uint8List?> readSealed(String id) async {
    final file = sealedFile(await resolve(), id);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<void> delete(String id) async {
    final dir = await resolve();
    await quietlyDelete(sealedFile(dir, id));
    await quietlyDelete(pendingFile(dir, id));
  }

  /// Efface le répertoire entier. Sans conséquence s'il est verrouillé ou déjà
  /// parti : les octets qui y restent ne sont plus déchiffrables par personne
  /// dès que la clé change.
  @override
  Future<void> deleteAll() async {
    try {
      final dir = await resolve();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {
      // Répertoire verrouillé ou déjà parti.
    }
  }

  /// Efface les fichiers que [indexedIds] ne désigne plus, ainsi que toute
  /// écriture restée en attente. Rend le nombre de fichiers retirés.
  ///
  /// Les fichiers qui ne portent pas nos noms sont laissés en place : ce
  /// répertoire nous appartient, mais rien ne prouve qu'il n'appartienne qu'à
  /// nous.
  @override
  Future<int> reclaimOrphans({required Set<String> indexedIds}) async {
    try {
      final dir = await resolve();
      if (!await dir.exists()) return 0;
      var removed = 0;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final fileName = p.basename(entity.path);
        final id = _idOf(fileName);
        if (id == null) continue;
        if (fileName.endsWith(sealedSuffix) && indexedIds.contains(id)) {
          continue;
        }
        await quietlyDelete(entity);
        removed++;
      }
      return removed;
    } catch (_) {
      return 0;
    }
  }

  /// Supprime [file] s'il existe, sans jamais lever.
  static Future<void> quietlyDelete(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Fichier déjà parti, verrouillé, ou répertoire disparu.
    }
  }

  /// Identifiant porté par un nom de fichier du magasin, `null` si le nom ne
  /// vient pas de nous (un fichier étranger déposé là n'est pas à effacer).
  static String? _idOf(String fileName) {
    for (final suffix in const [sealedSuffix, pendingSuffix]) {
      if (!fileName.endsWith(suffix)) continue;
      final id = fileName.substring(0, fileName.length - suffix.length);
      return isSafeId(id) ? id : null;
    }
    return null;
  }
}
