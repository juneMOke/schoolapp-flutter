import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_update_downloader.dart';
import 'package:school_app_flutter/features/desktop_update/data/installer_transfer.dart';
import 'package:school_app_flutter/features/desktop_update/domain/repositories/desktop_update_repository.dart';

/// Faux PowerShell : écrit [bytes] dans le fichier demandé, puis sort avec
/// [exitCode] — ou attend d'être tué quand [hang] est vrai.
class _FakeProcess implements Process {
  final _exit = Completer<int>();
  final String stderrText;
  bool killed = false;

  _FakeProcess({this.stderrText = ''});

  void finish(int code) {
    if (!_exit.isCompleted) _exit.complete(code);
  }

  @override
  Future<int> get exitCode => _exit.future;

  @override
  Stream<List<int>> get stderr => Stream.value(utf8.encode(stderrText));

  @override
  Stream<List<int>> get stdout => const Stream.empty();

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    finish(1);
    return true;
  }

  @override
  int get pid => 1;

  @override
  IOSink get stdin => throw UnimplementedError();
}

void main() {
  late Directory temp;
  late String target;
  late List<Object> calls;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('eteelo-ps');
    target = '${temp.path}/setup.exe.part';
    calls = [];
  });
  tearDown(() async => temp.delete(recursive: true));

  PowerShellInstallerTransfer transfer(
    _FakeProcess process, {
    void Function(Map<String, String> env)? onStart,
  }) => PowerShellInstallerTransfer(
    environment: {'SystemRoot': r'C:\Windows'},
    pollInterval: const Duration(milliseconds: 5),
    start: (executable, arguments, environment) async {
      calls.add([executable, arguments, environment]);
      onStart?.call(environment);
      return process;
    },
  );

  final url = Uri.parse('https://github.com/o/r/releases/download/t/s.exe');

  test(
    'lance PowerShell par son chemin complet, URL et fichier par l’environnement',
    () async {
      final process = _FakeProcess();
      final done = transfer(
        process,
        onStart: (env) {
          File(
            env[PowerShellInstallerTransfer.outputVariable]!,
          ).writeAsBytesSync(List.filled(10, 1));
          process.finish(0);
        },
      ).fetch(url, target, maxBytes: 10);
      await done;
      final call = calls.single as List;
      expect(
        call[0],
        r'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe',
      );
      expect(call[1], PowerShellInstallerTransfer.arguments);
      expect(call[2], {
        PowerShellInstallerTransfer.urlVariable: url.toString(),
        PowerShellInstallerTransfer.outputVariable: target,
      });
      // Le script ne contient ni l'URL ni le chemin.
      expect(PowerShellInstallerTransfer.script, isNot(contains('github')));
    },
  );

  test('échec de PowerShell : la cause remonte telle quelle', () async {
    final process = _FakeProcess(
      stderrText: 'The underlying connection was closed: trust relationship',
    );
    final future = transfer(process).fetch(url, target, maxBytes: 10);
    process.finish(1);
    await expectLater(
      future,
      throwsA(
        isA<DownloadTransferException>().having(
          (e) => e.detail,
          'detail',
          contains('trust relationship'),
        ),
      ),
    );
  });

  test('annulation : PowerShell est arrêté', () async {
    final process = _FakeProcess();
    final cancellation = DownloadCancellation();
    final future = transfer(
      process,
    ).fetch(url, target, maxBytes: 10, cancellation: cancellation);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    cancellation.cancel();
    await expectLater(future, throwsA(isA<DownloadCancelledException>()));
    expect(process.killed, isTrue);
  });

  test('plus d’octets que prévu : arrêt et refus', () async {
    final process = _FakeProcess();
    File(target).writeAsBytesSync(List.filled(20, 1));
    await expectLater(
      transfer(process).fetch(url, target, maxBytes: 10),
      throwsA(isA<DownloadIntegrityException>()),
    );
    expect(process.killed, isTrue);
  });

  test('la progression suit la taille du fichier', () async {
    final process = _FakeProcess();
    final seen = <int>[];
    final future = transfer(
      process,
    ).fetch(url, target, maxBytes: 10, onProgress: seen.add);
    File(target).writeAsBytesSync(List.filled(4, 1));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    File(target).writeAsBytesSync(List.filled(10, 1));
    process.finish(0);
    await future;
    expect(seen, contains(4));
    expect(seen.last, 10);
  });
}
