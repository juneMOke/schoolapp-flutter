import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/desktop_update/domain/repositories/desktop_update_repository.dart';

/// L'installation n'a pas pu aller au bout ; l'ancienne version reste.
class DesktopInstallException implements Exception {
  final String message;
  const DesktopInstallException(this.message);

  @override
  String toString() => 'DesktopInstallException: $message';
}

/// Lance les processus du système. Injectable pour les tests.
abstract class ProcessLauncher {
  /// Démarre [executable] détaché : il survit à la fermeture de l'application.
  Future<void> startDetached(String executable, List<String> arguments);

  /// Exécute [executable] et attend sa fin.
  Future<ProcessResult> run(String executable, List<String> arguments);
}

class SystemProcessLauncher implements ProcessLauncher {
  const SystemProcessLauncher();

  @override
  Future<void> startDetached(String executable, List<String> arguments) =>
      Process.start(executable, arguments, mode: ProcessStartMode.detached);

  @override
  Future<ProcessResult> run(String executable, List<String> arguments) =>
      Process.run(executable, arguments);
}

/// Installe une version déjà contrôlée. Après un succès, l'appelant ferme
/// l'application : c'est le processus lancé ici qui ramène la nouvelle.
abstract class DesktopInstaller {
  Future<void> install(VerifiedInstaller installer);

  /// Après un lancement réussi, l'application se ferme-t-elle elle-même ?
  bool get appMustQuit;
}

/// Windows : l'installateur Inno Setup, silencieux. `/UPDATE` lui fait
/// relancer l'application (sa ligne `[Run]` ordinaire saute en silencieux) ;
/// `/CLOSEAPPLICATIONS` ferme l'instance en cours si elle traîne. Inno reprend
/// le mode de la première installation (pour l'utilisateur, ou pour tous avec
/// une demande d'élévation).
class WindowsDesktopInstaller implements DesktopInstaller {
  final ProcessLauncher _launcher;

  const WindowsDesktopInstaller([
    this._launcher = const SystemProcessLauncher(),
  ]);

  static const arguments = [
    '/VERYSILENT',
    '/SUPPRESSMSGBOXES',
    '/NORESTART',
    '/CLOSEAPPLICATIONS',
    '/UPDATE',
  ];

  /// Non : Inno Setup la ferme (`/CLOSEAPPLICATIONS`) au moment où il est
  /// prêt à copier. Si l'installateur échoue avant — élévation refusée,
  /// antivirus —, l'application reste ouverte au lieu de disparaître.
  @override
  bool get appMustQuit => false;

  @override
  Future<void> install(VerifiedInstaller installer) =>
      _launcher.startDetached(installer.path, arguments);
}

/// Linux : l'archive est décompressée à côté d'elle, son `install.sh` remplace
/// le dossier du canal (`~/.local/share/eteelo-connect` en prod,
/// `eteelo-connect-staging` en staging) sans toucher à la base, puis la
/// nouvelle version est relancée — deux secondes plus tard, le temps que
/// celle-ci se ferme et rende la base.
class LinuxDesktopInstaller implements DesktopInstaller {
  final ProcessLauncher _launcher;
  final Map<String, String> _environment;

  /// Le canal de ce poste (`prod`, `staging`, `dev`) : il choisit le dossier.
  final String channel;

  LinuxDesktopInstaller({
    required this.channel,
    ProcessLauncher launcher = const SystemProcessLauncher(),
    Map<String, String>? environment,
  }) : _launcher = launcher,
       _environment = environment ?? Platform.environment;

  /// Le dossier du programme pour [channel] — même règle que `install.sh` :
  /// la prod garde `eteelo-connect`, les autres canaux y ajoutent leur nom,
  /// pour qu'une staging ne remplace jamais la prod du poste.
  static String installDirName(String channel) =>
      channel == 'prod' ? 'eteelo-connect' : 'eteelo-connect-$channel';

  /// Là où `install.sh` pose le programme (même règle que lui).
  String get installedExecutable {
    final dataHome = _environment['XDG_DATA_HOME'];
    final base = (dataHome == null || dataHome.isEmpty)
        ? p.join(_environment['HOME'] ?? '', '.local', 'share')
        : dataHome;
    return p.join(base, installDirName(channel), 'school_app_flutter');
  }

  @override
  bool get appMustQuit => true;

  @override
  Future<void> install(VerifiedInstaller installer) async {
    final extractDir = Directory(p.join(p.dirname(installer.path), 'extract'));
    if (await extractDir.exists()) await extractDir.delete(recursive: true);
    await extractDir.create(recursive: true);

    await _check('tar', ['-xzf', installer.path, '-C', extractDir.path]);
    // Le dossier de l'archive reste `eteelo-connect` quel que soit le canal :
    // les postes déjà installés y cherchent `install.sh`.
    final script = p.join(extractDir.path, 'eteelo-connect', 'install.sh');
    if (!await File(script).exists()) {
      throw const DesktopInstallException('install.sh absent de l’archive');
    }
    await _check('bash', [script]);
    await _launcher.startDetached('sh', [
      '-c',
      'sleep 2; exec "\$0"',
      installedExecutable,
    ]);
  }

  Future<void> _check(String executable, List<String> arguments) async {
    // Un `install.sh` qui ne rend jamais la main (disque réseau gelé) ne doit
    // pas laisser la fenêtre en « Installation » à vie.
    final result = await _launcher
        .run(executable, arguments)
        .timeout(AppConstants.desktopUpdateInstallTimeout);
    if (result.exitCode != 0) {
      throw DesktopInstallException(
        '$executable (${result.exitCode}) : ${result.stderr}',
      );
    }
  }
}
