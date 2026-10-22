import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/attachments/ephemeral_attachment_cache.dart';

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);

  group('sur disque', () {
    late Directory tmp;
    late EphemeralAttachmentCache cache;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('attachments_test');
      cache = EphemeralAttachmentCache(
        temporaryDirectory: () async => tmp,
        inMemory: false,
      );
    });
    tearDown(() async {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    test('une pièce écrite se relit par son empreinte', () async {
      await cache.write('abc', bytes);
      expect(await cache.contains('abc'), isTrue);
      expect(await cache.read('abc'), bytes);
      expect(await cache.read('autre'), isNull);
    });

    test('la purge efface tout le dossier', () async {
      await cache.write('abc', bytes);
      await cache.purge();
      expect(await cache.contains('abc'), isFalse);
      expect(await Directory('${tmp.path}/attachments').exists(), isFalse);
    });

    test('une empreinte ne sort jamais du dossier', () async {
      await cache.write('../../evasion', bytes);
      expect(await File('${tmp.path}/evasion').exists(), isFalse);
      expect(await cache.read('../../evasion'), bytes);
    });

    test('un dossier introuvable rend « pas en cache », sans lever', () async {
      final broken = EphemeralAttachmentCache(
        temporaryDirectory: () async => throw const FileSystemException(),
        inMemory: false,
      );
      await broken.write('abc', bytes);
      expect(await broken.read('abc'), isNull);
      await broken.purge();
    });
  });

  test('en mémoire (web) : même contrat', () async {
    final cache = EphemeralAttachmentCache(inMemory: true);
    await cache.write('abc', bytes);
    expect(await cache.read('abc'), bytes);
    await cache.purge();
    expect(await cache.contains('abc'), isFalse);
  });
}
