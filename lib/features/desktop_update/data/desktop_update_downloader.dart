import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:school_app_flutter/features/desktop_update/data/installer_transfer.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/desktop_release.dart';
import 'package:school_app_flutter/features/desktop_update/domain/repositories/desktop_update_repository.dart';

/// La taille ou l'empreinte du fichier ne sont pas celles de la fiche signée.
class DownloadIntegrityException implements Exception {
  final String reason;
  const DownloadIntegrityException(this.reason);

  @override
  String toString() => 'DownloadIntegrityException: $reason';
}

/// Télécharge un installateur dans le dossier temporaire du poste et ne le
/// rend qu'après avoir contrôlé sa taille et son SHA-256.
///
/// Le fichier s'écrit d'abord sous `.part` : un téléchargement interrompu ne
/// laisse jamais un fichier qui aurait l'air complet. Un fichier final déjà
/// présent et intact (téléchargement d'une séance précédente) est réutilisé.
class DesktopUpdateDownloader {
  final InstallerTransfer _transfer;
  final Future<Directory> Function() _baseDirectory;

  DesktopUpdateDownloader({
    required InstallerTransfer transfer,
    required Future<Directory> Function() baseDirectory,
  }) : _transfer = transfer,
       _baseDirectory = baseDirectory;

  Future<String> download(
    DesktopRelease release, {
    void Function(int received, int total)? onProgress,
    DownloadCancellation? cancellation,
  }) async {
    final root = Directory(
      p.join((await _baseDirectory()).path, 'eteelo-update'),
    );
    await _ensurePrivate(root);
    await _purgeExcept(root, '${release.version}');
    final dir = Directory(p.join(root.path, '${release.version}'));
    await dir.create();
    final target = File(p.join(dir.path, release.fileName));
    if (await target.exists()) {
      if (await _matches(target, release)) return target.path;
      await target.delete();
    }
    final partial = File('${target.path}.part');
    if (await partial.exists()) await partial.delete();
    try {
      await _transfer.fetch(
        release.url,
        partial.path,
        maxBytes: release.size,
        onProgress: (received) => onProgress?.call(received, release.size),
        cancellation: cancellation,
      );
      if (!await _matches(partial, release)) {
        throw const DownloadIntegrityException('taille ou empreinte');
      }
      await partial.rename(target.path);
      return target.path;
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
  }

  /// Le dossier de travail est propre à l'utilisateur ; sous Linux, il est
  /// de plus fermé aux autres comptes (0700) et doit lui appartenir : un
  /// dossier posé d'avance par quelqu'un d'autre permettrait de remplacer
  /// l'archive ou `install.sh` entre le contrôle et le lancement.
  static Future<void> _ensurePrivate(Directory root) async {
    await root.create(recursive: true);
    if (!Platform.isLinux) return;
    await Process.run('chmod', ['700', root.path]);
    final stat = await Process.run('stat', ['-c', '%u %a', root.path]);
    final uid = await Process.run('id', ['-u']);
    final parts = '${stat.stdout}'.trim().split(' ');
    if (parts.length != 2 ||
        parts.first != '${uid.stdout}'.trim() ||
        parts.last != '700') {
      throw FileSystemException('dossier de mise à jour non privé', root.path);
    }
  }

  /// Les versions précédentes (20 à 100 Mo chacune) ne servent plus.
  static Future<void> _purgeExcept(Directory root, String keep) async {
    await for (final entry in root.list(followLinks: false)) {
      if (p.basename(entry.path) == keep) continue;
      try {
        await entry.delete(recursive: true);
      } catch (_) {
        // Un fichier verrouillé (Windows) partira la prochaine fois.
      }
    }
  }

  static Future<bool> _matches(File file, DesktopRelease release) async {
    if (await file.length() != release.size) return false;
    return await sha256Of(file) == release.sha256;
  }

  /// SHA-256 du fichier, en hexadécimal minuscule, lu par morceaux.
  static Future<String> sha256Of(File file) async {
    final sink = Sha256().newHashSink();
    await for (final chunk in file.openRead()) {
      sink.add(chunk);
    }
    sink.close();
    final hash = await sink.hash();
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
