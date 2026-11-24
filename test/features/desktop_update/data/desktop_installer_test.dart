import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_installer.dart';
import 'package:school_app_flutter/features/desktop_update/domain/repositories/desktop_update_repository.dart';

import '../fixtures.dart';

class _Launcher implements ProcessLauncher {
  final List<List<String>> runs = [];
  final List<List<String>> detached = [];
  int exitCode = 0;
  void Function(List<String>)? onRun;

  @override
  Future<ProcessResult> run(String executable, List<String> arguments) async {
    runs.add([executable, ...arguments]);
    onRun?.call([executable, ...arguments]);
    return ProcessResult(0, exitCode, '', 'erreur');
  }

  @override
  Future<void> startDetached(String executable, List<String> arguments) async =>
      detached.add([executable, ...arguments]);
}

void main() {
  test(
    'Windows : installateur silencieux, avec /UPDATE pour la relance',
    () async {
      final launcher = _Launcher();
      await WindowsDesktopInstaller(
        launcher,
      ).install(VerifiedInstaller(path: r'C:\t\setup.exe', release: release()));
      expect(launcher.detached.single, [
        r'C:\t\setup.exe',
        '/VERYSILENT',
        '/SUPPRESSMSGBOXES',
        '/NORESTART',
        '/CLOSEAPPLICATIONS',
        '/UPDATE',
      ]);
    },
  );

  group('Linux', () {
    late Directory temp;

    setUp(
      () async => temp = await Directory.systemTemp.createTemp('eteelo-in'),
    );
    tearDown(() async => temp.delete(recursive: true));

    LinuxDesktopInstaller installer(_Launcher launcher) =>
        LinuxDesktopInstaller(
          channel: 'prod',
          launcher: launcher,
          environment: {'HOME': '/home/agent'},
          currentPid: 4242,
        );

    test(
      'décompresse, lance install.sh, relance le programme installé',
      () async {
        final launcher = _Launcher()
          ..onRun = (command) {
            // Le faux `tar` pose l'archive décompressée.
            if (command.first == 'tar') {
              File('${command.last}/eteelo-connect/install.sh')
                ..createSync(recursive: true)
                ..writeAsStringSync('#!/bin/sh');
            }
          };
        final archive = '${temp.path}/eteelo.tar.gz';
        await installer(
          launcher,
        ).install(VerifiedInstaller(path: archive, release: release()));
        expect(launcher.runs.first, [
          'tar',
          '-xzf',
          archive,
          '-C',
          '${temp.path}/extract',
        ]);
        expect(launcher.runs.last, [
          'bash',
          '${temp.path}/extract/eteelo-connect/install.sh',
        ]);
        final relaunch = launcher.detached.single;
        expect(relaunch.sublist(relaunch.length - 2), [
          '/home/agent/.local/share/eteelo-connect/school_app_flutter',
          '4242',
        ]);
      },
    );

    test(
      'la relance attend la fin de cette instance avant de démarrer',
      () async {
        final launcher = _Launcher()
          ..onRun = (command) {
            if (command.first == 'tar') {
              File('${command.last}/eteelo-connect/install.sh')
                ..createSync(recursive: true)
                ..writeAsStringSync('#!/bin/sh');
            }
          };
        await installer(launcher).install(
          VerifiedInstaller(
            path: '${temp.path}/eteelo.tar.gz',
            release: release(),
          ),
        );
        final script = launcher.detached.single[2];
        expect(script, contains('kill -0 "\$1"'));
        expect(script, endsWith('exec "\$0"'));
      },
    );

    test('suit XDG_DATA_HOME comme install.sh', () {
      final linux = LinuxDesktopInstaller(
        channel: 'prod',
        launcher: _Launcher(),
        environment: {'HOME': '/home/agent', 'XDG_DATA_HOME': '/data'},
      );
      expect(
        linux.installedExecutable,
        '/data/eteelo-connect/school_app_flutter',
      );
    });

    test('la staging relance son propre dossier, jamais celui de la prod', () {
      LinuxDesktopInstaller of(String channel) => LinuxDesktopInstaller(
        channel: channel,
        launcher: _Launcher(),
        environment: {'HOME': '/home/agent'},
      );
      expect(
        of('staging').installedExecutable,
        '/home/agent/.local/share/eteelo-connect-staging/school_app_flutter',
      );
      expect(
        of('dev').installedExecutable,
        '/home/agent/.local/share/eteelo-connect-dev/school_app_flutter',
      );
      expect(
        of('prod').installedExecutable,
        '/home/agent/.local/share/eteelo-connect/school_app_flutter',
      );
    });

    test('un échec de tar arrête tout, rien n’est relancé', () async {
      final launcher = _Launcher()..exitCode = 2;
      await expectLater(
        installer(launcher).install(
          VerifiedInstaller(path: '${temp.path}/x.tar.gz', release: release()),
        ),
        throwsA(isA<DesktopInstallException>()),
      );
      expect(launcher.detached, isEmpty);
    });

    test('archive sans install.sh : refus', () async {
      final launcher = _Launcher();
      await expectLater(
        installer(launcher).install(
          VerifiedInstaller(path: '${temp.path}/x.tar.gz', release: release()),
        ),
        throwsA(isA<DesktopInstallException>()),
      );
      expect(launcher.detached, isEmpty);
    });
  });
}
