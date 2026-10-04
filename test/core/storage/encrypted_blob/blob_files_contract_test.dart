import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_cipher.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_directory.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_files.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_key_service.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/web_blob_files.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Le MÊME contrat pour le disque (tablette, poste) et pour le navigateur :
/// `EncryptedBlobStore` ne sait pas lequel il sert, les deux doivent donc se
/// comporter à l'identique. La version web tourne ici sur ffi — même SQL que
/// le WASM d'IndexedDB.
void main() {
  late Directory base;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    base = await Directory.systemTemp.createTemp('eteelo-blob-files-');
  });
  tearDown(() => base.delete(recursive: true));

  final implementations = <String, BlobFiles Function(String store)>{
    'disque': (store) =>
        BlobDirectory(name: store, baseDirectory: () async => base),
    'navigateur': (store) => WebBlobFiles(
      name: store,
      factory: databaseFactoryFfi,
      path: '${base.path}/blobs.db',
    ),
  };

  final sealed = Uint8List.fromList(List<int>.generate(64, (i) => i));

  for (final MapEntry(key: label, value: build) in implementations.entries) {
    group(label, () {
      test('une attente n est pas lisible avant engagement', () async {
        final files = build('cache');
        await files.writePending('a', sealed);

        expect(await files.sealedExists('a'), isFalse);
        expect(await files.readSealed('a'), isNull);
      });

      test('engager rend lisible, et une seule fois', () async {
        final files = build('cache');
        await files.writePending('a', sealed);

        expect(await files.commit('a'), isTrue);
        expect(await files.readSealed('a'), sealed);
        expect(await files.commit('a'), isFalse);
      });

      test('abandonner retire l attente, rien d engagé', () async {
        final files = build('cache');
        await files.writePending('a', sealed);
        await files.commit('a');
        await files.writePending('a', Uint8List.fromList([9]));

        await files.discardPending('a');

        expect(await files.commit('a'), isFalse);
        expect(await files.readSealed('a'), sealed);
      });

      test('retirer efface les deux états', () async {
        final files = build('cache');
        await files.writePending('a', sealed);
        await files.commit('a');
        await files.writePending('a', sealed);

        await files.delete('a');

        expect(await files.sealedExists('a'), isFalse);
        expect(await files.commit('a'), isFalse);
      });

      test('les orphelins et les attentes sont récupérés', () async {
        final files = build('cache');
        for (final id in ['gardee', 'orpheline']) {
          await files.writePending(id, sealed);
          await files.commit(id);
        }
        await files.writePending('en-attente', sealed);

        final removed = await files.reclaimOrphans(indexedIds: {'gardee'});

        expect(removed, 2);
        expect(await files.sealedExists('gardee'), isTrue);
        expect(await files.sealedExists('orpheline'), isFalse);
        expect(await files.commit('en-attente'), isFalse);
      });

      test('deux magasins ne se voient pas', () async {
        final editique = build('editique');
        final staff = build('staff');
        await editique.writePending('a', sealed);
        await editique.commit('a');

        expect(await staff.sealedExists('a'), isFalse);
        await staff.deleteAll();
        expect(await editique.sealedExists('a'), isTrue);
      });

      test('le magasin chiffré y fait l aller-retour', () async {
        final store = EncryptedBlobStore(
          directoryName: 'cache',
          keyService: _FixedKey(),
          cipher: runBlobCipherTask,
          files: build('cache'),
        );
        final pdf = Uint8List.fromList('%PDF-1.4 reçu'.codeUnits);

        expect(await store.stage(id: 'r1', bytes: pdf), isNotNull);
        expect(await store.commit('r1'), isTrue);
        final read = await store.read('r1');

        expect(read, isA<BlobFound>());
        expect((read as BlobFound).blob.bytes, pdf);
      });
    });
  }
}

class _FixedKey implements BlobKeyService {
  @override
  String get storageKey => 'test';

  @override
  Future<BlobKey> getOrCreate() async => BlobKey(
    bytes: Uint8List.fromList(List<int>.generate(32, (i) => i)),
    createdNow: false,
  );

  @override
  Future<void> destroy() async {}
}
