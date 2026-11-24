import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_update_downloader.dart';
import 'package:school_app_flutter/features/desktop_update/data/installer_transfer.dart';
import 'package:school_app_flutter/features/desktop_update/domain/repositories/desktop_update_repository.dart';

import '../fixtures.dart';

void main() {
  late HttpServer server;
  late Directory temp;
  late List<int> body;
  late int hits;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('eteelo-dl-test');
    body = List<int>.generate(61, (i) => i);
    hits = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      hits++;
      request.response
        ..contentLength = body.length
        ..add(body);
      request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    await temp.delete(recursive: true);
  });

  DesktopUpdateDownloader downloader() => DesktopUpdateDownloader(
    transfer: DioInstallerTransfer(Dio()),
    baseDirectory: () async => temp,
  );

  Future<String> digestOf(List<int> bytes) async {
    final file = File('${temp.path}/digest')..writeAsBytesSync(bytes);
    return DesktopUpdateDownloader.sha256Of(file);
  }

  String url() => 'http://127.0.0.1:${server.port}/t/setup.exe';

  test('rend le fichier quand taille et empreinte concordent', () async {
    final sha = await digestOf(body);
    final path = await downloader().download(
      release(sha256: sha, size: body.length, url: url()),
    );
    expect(File(path).readAsBytesSync(), body);
    expect(File('$path.part').existsSync(), isFalse);
  });

  test('efface tout et lève quand l’empreinte diffère', () async {
    final wrong = await digestOf([1, 2, 3]);
    final r = release(sha256: wrong, size: body.length, url: url());
    await expectLater(
      downloader().download(r),
      throwsA(isA<DownloadIntegrityException>()),
    );
    final dir = Directory('${temp.path}/eteelo-update/1.9.0');
    expect(dir.listSync(), isEmpty);
  });

  test('lève quand la taille diffère', () async {
    final sha = await digestOf(body);
    await expectLater(
      downloader().download(release(sha256: sha, size: 60, url: url())),
      throwsA(isA<DownloadIntegrityException>()),
    );
  });

  test('réutilise un fichier déjà téléchargé et intact', () async {
    final sha = await digestOf(body);
    final r = release(sha256: sha, size: body.length, url: url());
    await downloader().download(r);
    await downloader().download(r);
    expect(hits, 1);
  });

  test('l’annulation interrompt et ne laisse rien', () async {
    final sha = await digestOf(body);
    final cancellation = DownloadCancellation()..cancel();
    await expectLater(
      downloader().download(
        release(sha256: sha, size: body.length, url: url()),
        cancellation: cancellation,
      ),
      throwsA(isA<DioException>()),
    );
    final dir = Directory('${temp.path}/eteelo-update/1.9.0');
    expect(dir.listSync(), isEmpty);
  });

  test(
    'plus d’octets que la fiche n’en annonce : arrêt, rien ne reste',
    () async {
      final sha = await digestOf(body.sublist(0, 10));
      await expectLater(
        downloader().download(release(sha256: sha, size: 10, url: url())),
        throwsA(isA<DownloadIntegrityException>()),
      );
      final dir = Directory('${temp.path}/eteelo-update/1.9.0');
      expect(dir.listSync(), isEmpty);
    },
  );

  test('les versions précédentes sont nettoyées', () async {
    final old = Directory('${temp.path}/eteelo-update/1.8.0')
      ..createSync(recursive: true);
    File('${old.path}/setup.exe').writeAsStringSync('ancien');
    final sha = await digestOf(body);
    await downloader().download(
      release(sha256: sha, size: body.length, url: url()),
    );
    expect(old.existsSync(), isFalse);
  });

  test(
    'Linux : le dossier de travail est fermé aux autres comptes',
    () async {
      final sha = await digestOf(body);
      await downloader().download(
        release(sha256: sha, size: body.length, url: url()),
      );
      final mode = Process.runSync('stat', [
        '-c',
        '%a',
        '${temp.path}/eteelo-update',
      ]);
      expect('${mode.stdout}'.trim(), '700');
    },
    skip: !Platform.isLinux,
  );
}
