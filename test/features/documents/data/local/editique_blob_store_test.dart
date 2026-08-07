import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:school_app_flutter/features/documents/data/local/editique_blob_cipher.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_blob_store.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_key_service.dart';

/// Clé de magasin pilotée par le test : sa nouveauté, le nombre de fois qu'on
/// la demande et sa capacité à échouer sont eux-mêmes des faits à vérifier.
class _FakeKeyService implements EditiqueCacheKeyService {
  _FakeKeyService({int seed = 0, this.createdNow = false})
    : bytes = Uint8List.fromList(
        List<int>.generate(32, (i) => (i + seed) & 0xFF),
      );

  final Uint8List bytes;
  bool createdNow;
  int reads = 0;
  int destructions = 0;

  /// Nombre d'appels qui doivent échouer avant que la clé ne se laisse lire.
  int failures = 0;

  /// Retarde la réponse, pour ouvrir la fenêtre de course entre deux
  /// résolutions concurrentes.
  Duration delay = Duration.zero;

  @override
  Future<EditiqueCacheKey> getOrCreate() async {
    reads++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (failures > 0) {
      failures--;
      throw const FileSystemException('secure storage indisponible');
    }
    return EditiqueCacheKey(bytes: bytes, createdNow: createdNow);
  }

  @override
  Future<void> destroy() async => destructions++;
}

void main() {
  late Directory base;
  late Directory cacheDir;
  late _FakeKeyService keys;

  final pdf = Uint8List.fromList([
    ...'%PDF-1.4 note de perception'.codeUnits,
    ...List<int>.generate(500, (i) => i & 0xFF),
  ]);

  setUp(() async {
    base = await Directory.systemTemp.createTemp('eteelo-editique-blobs-');
    cacheDir = Directory(p.join(base.path, 'editique_cache'));
    keys = _FakeKeyService();
  });

  tearDown(() async {
    if (await base.exists()) await base.delete(recursive: true);
  });

  EditiqueBlobStore storeWith({
    _FakeKeyService? keyService,
    EditiqueCipherOffloader? cipher,
    Future<void> Function()? onKeyRotated,
  }) => EditiqueBlobStore(
    keyService: keyService ?? keys,
    // Le chemin d'isolat est exercé par le test du chiffrement lui-même ;
    // ici on veut des écritures déterministes et rapides.
    cipher: cipher ?? runEditiqueCipherTask,
    baseDirectory: () async => base,
    onKeyRotated: onKeyRotated,
  );

  /// Le geste complet — sceller puis publier — que le coordinateur découpe.
  Future<EditiqueStoredBlob?> save(
    EditiqueBlobStore store, {
    required String id,
    required Uint8List bytes,
  }) async {
    final staged = await store.stage(id: id, bytes: bytes);
    if (staged == null) return null;
    return await store.commit(id) ? staged : null;
  }

  Future<Uint8List?> bytesOf(EditiqueBlobStore store, String id) async {
    final read = await store.read(id);
    return read is EditiqueBlobFound ? read.blob.bytes : null;
  }

  List<String> filesOnDisk() => cacheDir.existsSync()
      ? (cacheDir.listSync().map((f) => p.basename(f.path)).toList()..sort())
      : <String>[];

  group('aller-retour', () {
    test('rend les octets scellés, à l identique', () async {
      final store = storeWith();

      final stored = await save(store, id: 'c-1', bytes: pdf);

      expect(stored, isNotNull);
      expect(await bytesOf(store, 'c-1'), equals(pdf));
    });

    test('mesure le clair, pas le fichier', () async {
      final stored = await save(storeWith(), id: 'c-1', bytes: pdf);

      expect(stored!.clearSizeBytes, pdf.length);
      expect(stored.fileSizeBytes, pdf.length + 33);
    });

    // Le nom vient de la clé locale : un listing de répertoire ne doit trahir
    // ni le type de pièce, ni son rang, ni l'élève.
    test('nomme le fichier d après l identifiant, et rien d autre', () async {
      await save(storeWith(), id: 'c-1', bytes: pdf);

      expect(filesOnDisk(), ['c-1.enc']);
    });

    // Le critère d'acceptation de l'ADR : aucune pièce en clair hors de la zone
    // chiffrée, y compris dans les caches système.
    test('n écrit jamais le PDF en clair sur le disque', () async {
      await save(storeWith(), id: 'c-1', bytes: pdf);

      final surDisque = File(
        p.join(cacheDir.path, 'c-1.enc'),
      ).readAsBytesSync();
      expect(surDisque, isNot(equals(pdf)));
      expect(String.fromCharCodes(surDisque).contains('%PDF'), isFalse);
    });

    test('réécrit une pièce déjà stockée sans en laisser deux', () async {
      final store = storeWith();
      final autre = Uint8List.fromList('%PDF-1.4 version 2'.codeUnits);

      await save(store, id: 'c-1', bytes: pdf);
      await save(store, id: 'c-1', bytes: autre);

      expect(await bytesOf(store, 'c-1'), equals(autre));
      expect(filesOnDisk(), ['c-1.enc']);
    });
  });

  // Ce qui rend une écriture annulable : tant qu'elle n'est pas publiée, la
  // pièce en place reste la pièce en place.
  group('écriture en deux temps', () {
    test('une écriture scellée mais non publiée ne se relit pas', () async {
      final store = storeWith();

      await store.stage(id: 'c-1', bytes: pdf);

      expect(await store.read('c-1'), isA<EditiqueBlobGone>());
      expect(filesOnDisk(), ['c-1.part']);
    });

    test('abandonner laisse intacte la pièce déjà publiée', () async {
      final store = storeWith();
      await save(store, id: 'c-1', bytes: pdf);
      final v2 = Uint8List.fromList('%PDF-1.4 version 2'.codeUnits);

      await store.stage(id: 'c-1', bytes: v2);
      await store.discard('c-1');

      expect(await bytesOf(store, 'c-1'), equals(pdf));
      expect(filesOnDisk(), ['c-1.enc']);
    });

    test('publier sans avoir scellé ne fait rien', () async {
      expect(await storeWith().commit('c-1'), isFalse);
      expect(filesOnDisk(), isEmpty);
    });

    // Le test que la revue réclamait : rendre l'interruption observable. Un
    // RÉPERTOIRE au nom du fichier d'attente fait échouer l'écriture là où un
    // arrêt brutal la couperait.
    test('un scellement impossible laisse la pièce publiée intacte', () async {
      final store = storeWith();
      await save(store, id: 'c-1', bytes: pdf);
      Directory(p.join(cacheDir.path, 'c-1.part')).createSync();

      final staged = await store.stage(id: 'c-1', bytes: Uint8List(64));

      expect(staged, isNull);
      expect(await bytesOf(store, 'c-1'), equals(pdf));
    });
  });

  group('lecture d une pièce qui ne répond pas', () {
    test('une pièce absente est perdue, pas indisponible', () async {
      expect(await storeWith().read('jamais-vue'), isA<EditiqueBlobGone>());
    });

    // La DI offline est câblée AVANT l'authentification : constater un cache
    // vide ne doit fabriquer ni clé AES ni répertoire, sans quoi la tablette
    // d'un profil sans droit de restitution en aurait déjà.
    test('constater l absence ne crée ni clé ni répertoire', () async {
      await storeWith().read('jamais-vue');

      expect(await cacheDir.exists(), isFalse);
      expect(keys.reads, 0);
    });

    test('un fichier corrompu est perdu', () async {
      final store = storeWith();
      await save(store, id: 'c-1', bytes: pdf);
      final file = File(p.join(cacheDir.path, 'c-1.enc'));
      file.writeAsBytesSync(file.readAsBytesSync()..[30] ^= 0xFF);

      expect(await store.read('c-1'), isA<EditiqueBlobGone>());
    });

    test('une pièce scellée par une autre clé est perdue', () async {
      await save(storeWith(), id: 'c-1', bytes: pdf);

      final autre = storeWith(keyService: _FakeKeyService(seed: 9));
      expect(await autre.read('c-1'), isA<EditiqueBlobGone>());
    });

    // Un fichier déplacé sur le nom d'une autre entrée : le sceau le refuse,
    // et l'index ne peut donc pas servir les octets d'une autre pièce.
    test('un fichier renommé sur une autre entrée est perdu', () async {
      final store = storeWith();
      await save(store, id: 'c-1', bytes: pdf);
      File(
        p.join(cacheDir.path, 'c-1.enc'),
      ).renameSync(p.join(cacheDir.path, 'c-2.enc'));

      expect(await store.read('c-2'), isA<EditiqueBlobGone>());
    });

    test('un identifiant impropre est perdu, pas levé', () async {
      expect(
        await storeWith().read('../../etc/passwd'),
        isA<EditiqueBlobGone>(),
      );
    });
  });

  // La distinction qui décide si l'appelant a le droit de détruire la ligne
  // d'index. Hors ligne, se tromper de côté coûte le document.
  group('panne passagère, pièce intacte', () {
    test('un secure storage muet rend indisponible, pas perdu', () async {
      final store = storeWith();
      await save(store, id: 'c-1', bytes: pdf);

      final apresPanne = storeWith(keyService: _FakeKeyService()..failures = 1);
      expect(await apresPanne.read('c-1'), isA<EditiqueBlobUnavailable>());
    });

    test('un calcul qui n aboutit pas rend indisponible', () async {
      await save(storeWith(), id: 'c-1', bytes: pdf);

      final store = storeWith(
        cipher: (_) async => throw StateError('isolat impossible'),
      );
      expect(await store.read('c-1'), isA<EditiqueBlobUnavailable>());
    });

    test('un répertoire de base introuvable rend indisponible', () async {
      final store = EditiqueBlobStore(
        keyService: keys,
        cipher: runEditiqueCipherTask,
        baseDirectory: () async => throw const FileSystemException('absent'),
      );

      expect(await store.read('c-1'), isA<EditiqueBlobUnavailable>());
    });

    // Un échec de résolution mémoïsé condamnerait le cache pour toute la durée
    // du processus, alors que le Keystore peut n'avoir été indisponible qu'au
    // démarrage.
    test('un échec de clé ne se mémoïse pas', () async {
      await save(storeWith(), id: 'c-1', bytes: pdf);
      // Même clé, mais muette au premier appel : le Keystore n'était pas encore
      // disponible au démarrage.
      final store = storeWith(keyService: _FakeKeyService()..failures = 1);

      expect(await store.read('c-1'), isA<EditiqueBlobUnavailable>());
      expect(await bytesOf(store, 'c-1'), equals(pdf));
    });
  });

  group('identifiants impropres à l écriture', () {
    test('refusent d écrire, et rien ne sort du répertoire', () async {
      final store = storeWith();

      for (final id in ['../evade', 'a/b', '', 'avec espace', 'point.point']) {
        expect(
          () => store.stage(id: id, bytes: pdf),
          throwsA(isA<ArgumentError>()),
          reason: id,
        );
      }
      expect(await cacheDir.exists(), isFalse);
    });

    test('acceptent la forme d un UUID v4', () async {
      final store = storeWith();
      const uuid = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';

      expect(await save(store, id: uuid, bytes: pdf), isNotNull);
      expect(await bytesOf(store, uuid), equals(pdf));
    });
  });

  group('effacement', () {
    test('efface le fichier d une pièce', () async {
      final store = storeWith();
      await save(store, id: 'c-1', bytes: pdf);

      expect(await store.delete('c-1'), isTrue);
      expect(await store.read('c-1'), isA<EditiqueBlobGone>());
      expect(filesOnDisk(), isEmpty);
    });

    test('effacer une pièce absente n est pas un échec', () async {
      expect(await storeWith().delete('jamais-vue'), isTrue);
    });

    test('shredAll emporte le répertoire ET la clé', () async {
      final store = storeWith();
      await save(store, id: 'c-1', bytes: pdf);

      await store.shredAll();

      expect(await cacheDir.exists(), isFalse);
      expect(keys.destructions, 1);
    });

    // Après un effacement complet, le magasin doit redemander sa clé : la
    // garder en mémoire servirait des octets sous une clé officiellement
    // détruite.
    test('shredAll oublie la clé tenue en mémoire', () async {
      final store = storeWith();
      await save(store, id: 'c-1', bytes: pdf);
      expect(keys.reads, 1);

      await store.shredAll();
      await save(store, id: 'c-2', bytes: pdf);

      expect(keys.reads, 2);
    });
  });

  group('réclamation des orphelins', () {
    test('efface les fichiers que l index ne désigne plus', () async {
      final store = storeWith();
      await save(store, id: 'c-1', bytes: pdf);
      await save(store, id: 'c-2', bytes: pdf);

      final removed = await store.reclaimOrphans(indexedIds: {'c-1'});

      expect(removed, 1);
      expect(await bytesOf(store, 'c-1'), equals(pdf));
      expect(await store.read('c-2'), isA<EditiqueBlobGone>());
    });

    // Une écriture interrompue laisse un fichier d'attente ; hors écriture en
    // cours — ce que le cache composé garantit — il ne peut être que mort.
    test('efface les écritures restées en attente', () async {
      final store = storeWith();
      await save(store, id: 'c-1', bytes: pdf);
      await store.stage(id: 'c-2', bytes: pdf);

      expect(await store.reclaimOrphans(indexedIds: {'c-1'}), 1);
      expect(filesOnDisk(), ['c-1.enc']);
    });

    // Le répertoire nous appartient, mais rien ne prouve qu'il n'appartienne
    // qu'à nous : ce qui ne porte pas nos noms reste en place.
    test('ne touche pas aux fichiers qui ne sont pas les nôtres', () async {
      final store = storeWith();
      await save(store, id: 'c-1', bytes: pdf);
      final etranger = File(p.join(cacheDir.path, 'lisez-moi.txt'))
        ..writeAsStringSync('bonjour');

      await store.reclaimOrphans(indexedIds: const {});

      expect(etranger.existsSync(), isTrue);
    });

    test('sur un cache jamais écrit, ne fait rien', () async {
      expect(await storeWith().reclaimOrphans(indexedIds: const {}), 0);
    });
  });

  group('clé neuve', () {
    // Restauration de sauvegarde, réinstallation, keystore effacé : les
    // fichiers sont là, la clé qui les ouvrait n'existe plus. Les garder
    // occuperait le budget avec des octets que personne ne rouvrira.
    test('efface les octets qu aucune clé n ouvrira plus', () async {
      await save(storeWith(), id: 'c-1', bytes: pdf);
      expect(File(p.join(cacheDir.path, 'c-1.enc')).existsSync(), isTrue);

      final apresRestauration = storeWith(
        keyService: _FakeKeyService(seed: 5, createdNow: true),
      );
      final relu = await apresRestauration.read('c-1');

      expect(relu, isA<EditiqueBlobUnavailable>());
      expect(await cacheDir.exists(), isFalse);
    });

    // Sans cet avertissement, l'index continue d'annoncer au budget des pièces
    // qui n'existent plus, et rien ne le détrompe.
    test('prévient l index que ses lignes ne décrivent plus rien', () async {
      var avertissements = 0;
      final store = storeWith(
        keyService: _FakeKeyService(createdNow: true),
        onKeyRotated: () async => avertissements++,
      );

      await save(store, id: 'c-1', bytes: pdf);
      await save(store, id: 'c-2', bytes: pdf);

      expect(
        avertissements,
        1,
        reason: 'une seule fois, pas à chaque écriture',
      );
    });

    test('n efface qu une fois, pas à chaque écriture', () async {
      final store = storeWith(keyService: _FakeKeyService(createdNow: true));

      await save(store, id: 'c-1', bytes: pdf);
      await save(store, id: 'c-2', bytes: pdf);

      expect(filesOnDisk(), ['c-1.enc', 'c-2.enc']);
    });

    // Les lectures ne passent pas par le verrou du cache : deux résolutions
    // peuvent démarrer ensemble. Si chacune fabrique sa clé, le secure storage
    // garde la dernière écrite et tout ce que l'autre a scellé est perdu.
    test('deux résolutions concurrentes ne fabriquent qu une clé', () async {
      final lente = _FakeKeyService()..delay = const Duration(milliseconds: 20);
      final store = storeWith(keyService: lente);

      await Future.wait([
        save(store, id: 'c-1', bytes: pdf),
        store.read('c-2'),
        store.stage(id: 'c-3', bytes: pdf),
      ]);

      expect(lente.reads, 1);
    });
  });

  group('pannes', () {
    test('un scellement qui échoue ne laisse aucun fichier', () async {
      final store = storeWith(
        cipher: (_) async => throw const EditiqueCipherException('panne'),
      );

      expect(await store.stage(id: 'c-1', bytes: pdf), isNull);
      expect(filesOnDisk(), isEmpty);
    });

    test('un répertoire de base introuvable ne fait pas lever', () async {
      final store = EditiqueBlobStore(
        keyService: keys,
        cipher: runEditiqueCipherTask,
        baseDirectory: () async => throw const FileSystemException('absent'),
      );

      expect(await store.stage(id: 'c-1', bytes: pdf), isNull);
      expect(await store.commit('c-1'), isFalse);
      expect(await store.delete('c-1'), isFalse);
      expect(await store.reclaimOrphans(indexedIds: const {}), 0);
    });
  });
}
