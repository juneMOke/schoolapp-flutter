import 'dart:io';

import 'package:path/path.dart' as p;

/// Journal des échecs de la mise à jour, à côté du dossier de téléchargement :
/// l'écran ne montre qu'une catégorie (« vérifiez la connexion »), le journal
/// garde la vraie cause (certificat, proxy, disque) pour qui dépanne le poste.
///
/// Windows : `%LOCALAPPDATA%\com.junethink\ETEELO CONNECT\eteelo-update.log`.
/// Linux : `~/.cache/com.junethink.school_app_flutter/eteelo-update.log`.
class DesktopUpdateLog {
  final Future<Directory> Function() _baseDirectory;
  final DateTime Function() _now;

  DesktopUpdateLog({
    required Future<Directory> Function() baseDirectory,
    DateTime Function()? now,
  }) : _baseDirectory = baseDirectory,
       _now = now ?? DateTime.now;

  static const fileName = 'eteelo-update.log';

  /// Au-delà, le journal repart de zéro : il ne sert qu'aux derniers échecs.
  static const maxBytes = 64 * 1024;

  /// N'échoue jamais : un journal illisible ne doit pas masquer l'erreur
  /// qu'il voulait garder.
  Future<void> record(String event, Object cause) async {
    try {
      final file = File(p.join((await _baseDirectory()).path, fileName));
      final keep = await file.exists() && await file.length() < maxBytes;
      await file.writeAsString(
        '${_now().toIso8601String()} $event : $cause\n',
        mode: keep ? FileMode.append : FileMode.write,
        flush: true,
      );
    } catch (_) {}
  }
}
