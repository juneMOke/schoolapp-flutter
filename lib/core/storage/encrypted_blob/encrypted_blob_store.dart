import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_cipher.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_directory.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_key_service.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_read.dart';

export 'package:school_app_flutter/core/storage/encrypted_blob/blob_read.dart';

/// Un magasin d'octets : **des fichiers chiffrés, hors de la base**. Né pour
/// le cache de restitution éditique (ADR-012 AM-10, décision L0.0), il sert à
/// tout module qui garde des pièces sur la tablette ; chacun a son répertoire
/// ([BlobDirectory.name]) et sa clé ([BlobKeyService.storageKey]).
///
/// ## Pourquoi pas dans SQLite
///
/// Trois raisons vérifiées, dont une rédhibitoire : le `CursorWindow` d'Android
/// est figé à 16 Ko par `sqlcipher-android` et n'a aucun levier côté Dart —
/// l'écriture d'un blob passe, la **relecture lève**, et le défaut est invisible
/// en intégration continue, qui tourne sur un moteur ffi sans CursorWindow. S'y
/// ajoutent la connexion sqflite unique, qui sérialiserait un PDF de 120 Ko
/// avec les lectures du guichet, et l'effacement physique de D-7, ici
/// démontrable par suppression de répertoire.
///
/// ## Ce que la compaction devient
///
/// Le plan exigeait une stratégie de compaction — `VACUUM` planifié ou
/// `auto_vacuum INCREMENTAL` — sans laquelle une purge de 2 Gio ne rend aucun
/// octet au système de fichiers. **Sur l'axe de l'espace, elle est sans
/// objet** : supprimer un fichier rend ses octets immédiatement, et l'index qui
/// reste en base pèse ~200 octets par pièce, soit moins de 4 Mo au budget plein
/// (2 Gio ÷ 120 Ko ≈ 17 000 lignes). Il n'y a rien à compacter.
///
/// Sur l'axe de la confidentialité, il subsiste autre chose, qu'il faut dire
/// plutôt que laisser croire réglé : les **lignes d'index** purgées (élève,
/// numéro, année, école) restent dans les pages libres du fichier SQLCipher,
/// que rien ne compacte. Ce n'est pas propre à l'éditique — c'est vrai de
/// chaque table que le socle purge — et le trancher ici, pour une table seule,
/// donnerait l'illusion d'avoir traité la question. Les **octets des pièces**,
/// eux, sont bien partis : c'est ce que ce lot avait à garantir.
///
/// ## Ce que le magasin ne fait pas
///
/// Il ne connaît ni l'index, ni le budget, ni le classement LRU : il ne sait
/// qu'écrire, relire et effacer des octets sous un identifiant. La cohérence
/// entre les deux — ordre d'effacement, éviction, comptabilité — appartient à
/// l'appelant (pour l'éditique, `EditiqueDocumentCache`).
///
/// ## Échecs
///
/// Une panne d'entrée-sortie rend `null`, jamais une exception : un cache qu'on
/// n'a pas su écrire laisse la pièce servie en ligne, alors qu'une émission qui
/// échoue parce que son cache a échoué inverserait les priorités. Une **faute
/// d'appelant** — identifiant impropre à nommer un fichier — lève, elle, sans
/// ménagement.
class EncryptedBlobStore {
  final BlobKeyService _keyService;
  final BlobCipherOffloader _cipher;
  final BlobDirectory _files;

  /// Prévenu quand la clé s'est révélée neuve, donc quand tous les fichiers
  /// viennent d'être effacés. L'index qui les décrit doit partir avec eux :
  /// sans cela il continue d'annoncer au budget des pièces qui n'existent plus,
  /// et rien ne le détrompe tant que personne ne demande précisément l'une
  /// d'elles.
  final Future<void> Function() _onKeyRotated;

  /// Résolution de la clé, tenue **en tant que futur** et non en tant
  /// qu'octets.
  ///
  /// La nuance décide d'un défaut : mémoïser les octets laisse deux résolutions
  /// concurrentes constater toutes deux l'absence de clé, en générer deux, et
  /// n'en persister qu'une — celle qui écrit en dernier. Tout ce que l'autre a
  /// scellé entre-temps devient illisible pour toujours. Mémoïser le futur fait
  /// qu'une seule résolution existe, et que les autres s'y rattachent. Les
  /// lectures ne passent pas par le verrou du cache, ce cas n'a donc rien de
  /// théorique.
  Future<Uint8List>? _key;

  /// [directoryName] : sous-répertoire propre au magasin. [baseDirectory]
  /// n'est injecté que par les tests ; en production, le répertoire de support.
  EncryptedBlobStore({
    required String directoryName,
    required BlobKeyService keyService,
    BlobCipherOffloader? cipher,
    Future<Directory> Function()? baseDirectory,
    Future<void> Function()? onKeyRotated,
  }) : _keyService = keyService,
       _cipher = cipher ?? offloadBlobCipher,
       _files = BlobDirectory(
         name: directoryName,
         baseDirectory: baseDirectory ?? getApplicationSupportDirectory,
       ),
       _onKeyRotated = onKeyRotated ?? _noKeyRotationHandler;

  static Future<void> _noKeyRotationHandler() async {}

  /// Scelle [bytes] sous [id] **sans les rendre visibles** : les octets
  /// n'existent que dans un fichier d'attente, que [commit] seul promeut. Rend
  /// de quoi indexer la pièce, ou `null` si rien n'a pu être écrit.
  ///
  /// Ce temps d'attente n'est pas une précaution contre les fichiers tronqués —
  /// c'est ce qui rend l'écriture **annulable**. Sceller directement sur le nom
  /// définitif détruirait la copie précédente au moment même où on écrit la
  /// nouvelle : si l'index refusait ensuite la ligne, la pièce d'hier serait
  /// perdue en échange d'une pièce d'aujourd'hui que personne n'a acceptée.
  Future<StoredBlob?> stage({
    required String id,
    required Uint8List bytes,
  }) async {
    BlobDirectory.requireSafeId(id);
    try {
      final sealed = await _cipher(
        BlobCipherRequest(
          mode: BlobCipherMode.seal,
          keyBytes: await _resolveKey(),
          payload: bytes,
          entryId: id,
        ),
      );
      final dir = await _files.ensure();
      final pending = BlobDirectory.pendingFile(dir, id);
      await pending.writeAsBytes(sealed.bytes, flush: true);
      return StoredBlob(
        sha256Hex: sealed.sha256Hex,
        clearSizeBytes: sealed.clearSizeBytes,
        fileSizeBytes: sealed.bytes.length,
      );
    } catch (_) {
      // Disque plein, permission refusée, secure storage indisponible : la
      // pièce reste servie en ligne.
      await discard(id);
      return null;
    }
  }

  /// Promeut l'écriture en attente de [id] : elle devient **la** pièce. Le
  /// renommage est atomique sur un même système de fichiers, il n'existe donc
  /// aucun instant où le fichier définitif serait à moitié écrit.
  Future<bool> commit(String id) async {
    if (!BlobDirectory.isSafeId(id)) return false;
    try {
      final dir = await _files.resolve();
      final pending = BlobDirectory.pendingFile(dir, id);
      if (!await pending.exists()) return false;
      await pending.rename(BlobDirectory.sealedFile(dir, id).path);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Abandonne l'écriture en attente de [id], sans toucher à la pièce en place.
  Future<void> discard(String id) async {
    if (!BlobDirectory.isSafeId(id)) return;
    try {
      final dir = await _files.resolve();
      await BlobDirectory.quietlyDelete(BlobDirectory.pendingFile(dir, id));
    } catch (_) {
      // Répertoire introuvable : il n'y a rien à abandonner.
    }
  }

  /// Relit les octets scellés sous [id], en distinguant la pièce **perdue** de
  /// la panne **passagère** — voir [BlobRead].
  ///
  /// Un identifiant impropre est traité comme une pièce perdue plutôt que levé :
  /// à la lecture, il ne peut venir que d'une ligne d'index abîmée, et une
  /// restitution ne doit jamais faire tomber l'écran qui la demande.
  Future<BlobRead> read(String id) async {
    if (!BlobDirectory.isSafeId(id)) return const BlobGone();

    final File file;
    try {
      // L'absence se constate SANS toucher au secure storage ni créer quoi que
      // ce soit : la DI offline est câblée avant l'authentification, et un
      // profil qui n'a droit à aucune pièce (RG-012-4) ne doit pas se voir
      // fabriquer une clé de cache et un répertoire pour avoir ouvert un écran.
      file = BlobDirectory.sealedFile(await _files.resolve(), id);
      if (!await file.exists()) return const BlobGone();
    } catch (_) {
      return const BlobUnavailable();
    }

    final Uint8List key;
    final Uint8List sealed;
    try {
      // Ensuite seulement, la clé — dont la nouveauté éventuelle efface le
      // répertoire, et prévient l'index que les pièces qu'il décrit n'existent
      // plus.
      key = await _resolveKey();
      sealed = await file.readAsBytes();
    } catch (_) {
      // Keystore encore verrouillé au démarrage, descripteurs épuisés, disque
      // qui ne répond pas : la pièce est très probablement intacte. Ne rien
      // conclure, et surtout ne rien détruire.
      return const BlobUnavailable();
    }

    try {
      final opened = await _cipher(
        BlobCipherRequest(
          mode: BlobCipherMode.open,
          keyBytes: key,
          payload: sealed,
          entryId: id,
        ),
      );
      return BlobFound(
        LoadedBlob(bytes: opened.bytes, sha256Hex: opened.sha256Hex),
      );
    } on BlobCipherException {
      // Tronqué, étranger, version inconnue, sceau refusé : ces octets ne
      // s'ouvriront jamais, quel que soit le nombre de tentatives.
      return const BlobGone();
    } catch (_) {
      // Tout le reste — un isolat qui n'a pas pu naître, par exemple — est un
      // échec du calcul, pas un verdict sur la pièce.
      return const BlobUnavailable();
    }
  }

  /// Efface le fichier de [id]. Rend `true` s'il n'en reste rien — un fichier
  /// déjà absent compte comme effacé.
  Future<bool> delete(String id) async {
    if (!BlobDirectory.isSafeId(id)) return false;
    try {
      final dir = await _files.resolve();
      await BlobDirectory.quietlyDelete(BlobDirectory.sealedFile(dir, id));
      await BlobDirectory.quietlyDelete(BlobDirectory.pendingFile(dir, id));
      return !await BlobDirectory.sealedFile(dir, id).exists();
    } catch (_) {
      return false;
    }
  }

  /// Efface les fichiers que l'index ne désigne plus, ainsi que toute écriture
  /// restée en attente. Rend le nombre de fichiers retirés.
  ///
  /// C'est le filet de l'ordre d'effacement : une purge qui supprime les lignes
  /// avant les fichiers, interrompue au mauvais moment, laisse des octets que
  /// plus rien ne désigne — invisibles à la comptabilité de budget, jamais
  /// réclamés.
  ///
  /// **À n'appeler qu'en l'absence d'écriture en cours** : un fichier tout
  /// juste scellé dont la ligne n'est pas encore insérée serait pris pour un
  /// orphelin. L'appelant s'en porte garant en sérialisant ses écritures
  /// (l'éditique : `EditiqueDocumentCache`) ; c'est aussi ce qui permet
  /// d'effacer sans réfléchir les fichiers d'attente, qui ne peuvent alors
  /// venir que d'un arrêt brutal.
  Future<int> reclaimOrphans({required Set<String> indexedIds}) =>
      _files.reclaimOrphans(indexedIds: indexedIds);

  /// Efface **tout** : le répertoire, puis la clé.
  ///
  /// L'ordre importe pour ce que garantit un arrêt en cours de route. La clé
  /// détruite en dernier, un répertoire à moitié effacé laisse des octets ;
  /// mais la clé partie, ces octets ne sont plus déchiffrables par personne, et
  /// le prochain démarrage les balaiera en constatant la clé neuve. C'est
  /// l'effacement physique de D-7, obtenu sans dépendre de la réussite d'une
  /// suppression de fichier.
  Future<void> shredAll() async {
    await _files.deleteAll();
    await _keyService.destroy();
    // Oublier la clé tenue en mémoire fait partie de l'effacement : la garder
    // laisserait ce processus rouvrir les pièces d'un compte ou d'une école
    // qu'on vient précisément de congédier.
    _key = null;
  }

  /// Clé du magasin, résolue **une seule fois** — voir [_key].
  ///
  /// Un échec ne se mémoïse pas : un Keystore indisponible au démarrage
  /// condamnerait sinon le cache pour toute la durée du processus.
  Future<Uint8List> _resolveKey() {
    final pending = _key;
    if (pending != null) return pending;

    final resolution = _openKey();
    _key = resolution;
    return resolution.catchError((Object error) {
      _key = null;
      throw error;
    });
  }

  /// Une clé **neuve** signifie que tout fichier présent a été scellé avec une
  /// autre : ce sont des octets que plus aucune clé n'ouvrira. On les efface,
  /// et on prévient l'index, qui autrement continuerait de les compter.
  Future<Uint8List> _openKey() async {
    final key = await _keyService.getOrCreate();
    if (key.createdNow) {
      await _files.deleteAll();
      await _onKeyRotated();
    }
    return key.bytes;
  }
}
