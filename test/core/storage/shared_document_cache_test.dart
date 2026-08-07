import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:school_app_flutter/core/storage/shared_document_cache.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('eteelo-share-cache-');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  SharedDocumentCache cacheOn(Directory dir) =>
      SharedDocumentCache(temporaryDirectory: () async => dir);

  Future<File> seedSharedPdf(String name) async {
    final shareDir = Directory(p.join(tmp.path, 'share'));
    await shareDir.create(recursive: true);
    final file = File(p.join(shareDir.path, name));
    await file.writeAsString('%PDF-1.4 reçu');
    return file;
  }

  // Le cas qui motive tout : un reçu financier partagé par WhatsApp reste en
  // clair dans le cache, hors de la base chiffrée, indéfiniment.
  test('efface les pièces laissées en clair par le partage', () async {
    final receipt = await seedSharedPdf('ETL-RC-2526-000212.pdf');
    expect(await receipt.exists(), isTrue);

    final purged = await cacheOn(tmp).purge();

    expect(purged, isTrue);
    expect(await receipt.exists(), isFalse);
    expect(await Directory(p.join(tmp.path, 'share')).exists(), isFalse);
  });

  test('efface tout le contenu, y compris les sous-dossiers', () async {
    await seedSharedPdf('a.pdf');
    final nested = Directory(p.join(tmp.path, 'share', 'sous-dossier'));
    await nested.create(recursive: true);
    await File(p.join(nested.path, 'b.pdf')).writeAsString('x');

    await cacheOn(tmp).purge();

    expect(await Directory(p.join(tmp.path, 'share')).exists(), isFalse);
  });

  // Ne touche QUE le dossier du plugin : le cache applicatif contient aussi des
  // fichiers qui ne nous appartiennent pas.
  test('ne touche pas au reste du cache', () async {
    await seedSharedPdf('a.pdf');
    final other = File(p.join(tmp.path, 'autre-chose.bin'));
    await other.writeAsString('données');

    await cacheOn(tmp).purge();

    expect(await other.exists(), isTrue);
  });

  test('reste sans effet quand rien n a jamais été partagé', () async {
    expect(await cacheOn(tmp).purge(), isTrue);
  });

  // Best-effort : fermer la session prime sur nettoyer un cache. Une résolution
  // de répertoire qui échoue (canal de plateforme absent, permission refusée)
  // ne doit jamais faire échouer un wipe ni une déconnexion.
  test('ne lève jamais quand le cache est introuvable', () async {
    final cache = SharedDocumentCache(
      temporaryDirectory: () async => throw const FileSystemException('nope'),
    );

    expect(await cache.purge(), isFalse);
  });
}
