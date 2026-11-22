import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
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
  final Dio _dio;
  final Future<Directory> Function() _baseDirectory;

  DesktopUpdateDownloader({
    required Dio dio,
    required Future<Directory> Function() baseDirectory,
  }) : _dio = dio,
       _baseDirectory = baseDirectory;

  Future<String> download(
    DesktopRelease release, {
    void Function(int received, int total)? onProgress,
    DownloadCancellation? cancellation,
  }) async {
    final dir = Directory(
      p.join(
        (await _baseDirectory()).path,
        'eteelo-update',
        '${release.version}',
      ),
    );
    await dir.create(recursive: true);
    final target = File(p.join(dir.path, release.fileName));
    if (await target.exists()) {
      if (await _matches(target, release)) return target.path;
      await target.delete();
    }
    final partial = File('${target.path}.part');
    final cancelToken = CancelToken();
    cancellation?.onCancel(() => cancelToken.cancel());
    try {
      await _dio.downloadUri(
        release.url,
        partial.path,
        cancelToken: cancelToken,
        deleteOnError: true,
        onReceiveProgress: (received, total) =>
            onProgress?.call(received, total > 0 ? total : release.size),
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
