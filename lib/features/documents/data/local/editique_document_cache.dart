import 'dart:async';
import 'dart:typed_data';

import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/documents/data/local/editique_blob_store.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_maintenance_dao.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_entitlement.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_eviction_policy.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';

/// Le cache de restitution éditique **entier** : l'index en base et les octets
/// sur le disque, tenus cohérents (ADR-012 D-2/D-7, AM-10).
///
/// Les briques qu'il assemble savent chacune une chose et l'ignorent des
/// autres : [EditiqueCacheDao] retrouve et mesure, [EditiqueCacheMaintenanceDao]
/// retire, [EditiqueBlobStore] scelle et relit, [EditiqueCacheEvictionPolicy]
/// décide. Ce que personne d'autre ne peut tenir, et qui est donc ici :
///
///  - **l'ordre d'effacement** — le fichier d'abord, la ligne ensuite. Une
///    ligne survivant à son fichier est un défaut de cache, la pièce se
///    retélécharge ; un fichier survivant à sa ligne est un octet orphelin,
///    invisible à la comptabilité de budget, que plus rien ne réclamera ;
///  - **le nom du fichier** — la clé locale d'une ligne **existante**, jamais
///    une clé fraîche. Réécrire une pièce déjà connue sous un nouvel
///    identifiant laisserait son ancien fichier derrière elle ;
///  - **le balayage** — déclenché après l'écriture, seul moment où le budget
///    peut venir d'être franchi ;
///  - **la vérification d'intégrité** — l'empreinte relue comparée à celle de
///    l'index (RG-012-3). Le sceau AES-GCM prouve que le fichier n'a pas été
///    touché ; l'empreinte prouve que ce sont bien les octets que la ligne
///    décrit. Un arrêt entre l'écriture du fichier et celle de la ligne produit
///    exactement cet écart-là.
///
/// ## Une seule pièce à la fois
///
/// Toutes les opérations qui écrivent sont sérialisées. Deux raisons : chaque
/// pièce en vol coûte environ trois fois sa taille en mémoire (le clair, le
/// flot de clé, la concaténation — le paquet `cryptography` ne chiffre jamais
/// en place), ce qui sur une tablette d'administration n'est pas à multiplier
/// par le nombre d'onglets ouverts ; et deux écritures simultanées de la même
/// pièce feraient décrire au fichier survivant l'empreinte de l'autre, donc un
/// défaut de cache permanent jusqu'au retéléchargement.
///
/// Les **lectures** ne le sont pas : une restitution ne doit pas attendre la
/// fin d'un scellement de fond. Mais une lecture qui décide de **retirer** une
/// pièce cesse d'être une lecture — elle repasse alors par le verrou et refait
/// son constat, parce qu'un désaccord entre la ligne et le fichier est
/// exactement ce qu'on observe quand on regarde une écriture au milieu de son
/// cours.
///
/// ## Ce que le cache ne fait jamais
///
/// Lever. Un cache est un raccourci : quand il échoue, la pièce reste servie en
/// ligne. Une émission qui échouerait parce que sa mise en cache a échoué
/// inverserait les priorités. Deux exceptions, toutes deux des fautes
/// d'appelant que taire serait pire : une purge d'écoles étrangères sans école
/// courante, et un type de pièce que le serveur n'archive pas.
class EditiqueDocumentCache {
  final EditiqueCacheDao _index;
  final EditiqueCacheMaintenanceDao _maintenance;
  final EditiqueBlobStore _store;
  final EditiqueCacheEvictionPolicy _policy;
  final IdGenerator _ids;
  final EditiqueCacheAccess _access;
  final Clock _now;

  /// Chaîne de sérialisation des écritures. Voir « Une seule pièce à la fois ».
  Future<void> _pending = Future<void>.value();

  EditiqueDocumentCache({
    required EditiqueCacheDao index,
    required EditiqueCacheMaintenanceDao maintenance,
    required EditiqueBlobStore store,
    required IdGenerator ids,
    required EditiqueCacheAccess access,
    EditiqueCacheEvictionPolicy policy = const EditiqueCacheEvictionPolicy(),
    Clock now = systemClock,
  }) : _index = index,
       _maintenance = maintenance,
       _store = store,
       _policy = policy,
       _ids = ids,
       _access = access,
       _now = now;

  // ── Écriture ───────────────────────────────────────────────────────────────

  /// Met une pièce **définitive** en cache, octets compris, et balaie si le
  /// budget vient d'être franchi.
  ///
  /// Rend l'entrée indexée, ou `null` si la pièce n'a pas été mise en cache —
  /// ce qui n'est jamais une erreur pour l'appelant. Cinq raisons possibles,
  /// toutes sans conséquence : le type n'est pas archivé par le serveur
  /// (`RL`/`QT` : la copie locale serait l'unique exemplaire au monde et
  /// l'éviction la détruirait), la pièce n'est adressable ni par identifiant ni
  /// par numéro, le corps est vide, le disque n'a pas voulu, ou l'index n'a pas
  /// voulu. Dans aucun de ces cas la pièce déjà en cache n'est perdue.
  ///
  /// [bytes] doit être le corps de la réponse **tel que reçu** : RG-012-3 exige
  /// une restitution identique au bit près, et une pièce recomposée ne
  /// vérifierait plus son empreinte.
  Future<EditiqueCacheEntry?> put({
    required String docType,
    String? documentId,
    String? documentNumber,
    String? studentId,
    String? academicYearId,
    required String schoolId,
    String ownerUid = '',
    int? emittedAt,
    required Uint8List bytes,
  }) {
    return _exclusive(() async {
      // Les deux refus se prononcent AVANT le moindre octet écrit : un fichier
      // scellé pour une pièce que l'index refusera ensuite serait orphelin dès
      // sa naissance.
      // Garde de profil (RG-012-4). Le cache réside sur les tablettes
      // d'administration : un profil qui n'y a pas droit ne doit pas commencer
      // à accumuler des pièces scellées sur son disque. Le refus est silencieux
      // — la pièce vient d'être servie à l'écran, seule sa conservation est
      // refusée.
      if (!await _access.isEntitled()) return null;
      if (!EditiqueCacheEntry.isCacheableDocType(docType)) return null;
      final resolvedId = _blankToNull(documentId);
      final resolvedNumber = _blankToNull(documentNumber);
      if (resolvedId == null && resolvedNumber == null) return null;
      // Un corps vide n'est pas une pièce : le mettre en cache servirait hors
      // ligne un PDF de zéro octet, avec toutes les apparences d'un succès.
      if (bytes.isEmpty) return null;

      try {
        final existing = await _index.findIdentity(
          _identityProbe(
            documentId: resolvedId,
            documentNumber: resolvedNumber,
            docType: docType,
            schoolId: schoolId,
          ),
        );
        final id = existing?.id ?? _ids.newId();

        // Les octets sont scellés mais **pas encore visibles** : tant que
        // l'index n'a pas accepté la ligne, la pièce déjà en cache reste la
        // pièce en cache. C'est ce qui permet à un refus de l'index de ne rien
        // détruire.
        final stored = await _store.stage(id: id, bytes: bytes);
        if (stored == null) return null;

        final now = _now();
        final entry = EditiqueCacheEntry(
          id: id,
          documentId: resolvedId,
          documentNumber: resolvedNumber,
          // Forme canonique, celle que le schéma impose : l'entrée rendue doit
          // décrire ce qui est réellement stocké.
          docType: docType.toUpperCase(),
          studentId: studentId,
          academicYearId: academicYearId,
          schoolId: schoolId,
          ownerUid: ownerUid,
          // Le poids indexé est celui du CLAIR : c'est l'unité du budget, et le
          // surcoût du scellement (33 octets) ne se compte pas.
          sizeBytes: stored.clearSizeBytes,
          contentSha256: stored.sha256Hex,
          emittedAt: emittedAt,
          // Une pièce déjà connue garde sa date de mise en cache : la remettre
          // à maintenant effacerait son ancienneté réelle.
          createdAt: existing?.createdAt ?? now,
          lastAccessedAt: now,
        );

        try {
          await _index.upsert(entry);
        } catch (_) {
          // Ligne refusée — un numéro déjà pris par une autre pièce, par
          // exemple. On abandonne l'écriture en attente : la copie précédente
          // est intacte, et rien n'a été gaspillé qu'un scellement.
          await _store.discard(id);
          return null;
        }

        if (!await _store.commit(id)) {
          // La ligne annonce des octets qui ne sont pas au rendez-vous. Le cas
          // demande un système de fichiers en train de céder (le renommage est
          // atomique et local) ; la première restitution le constatera et
          // retirera la ligne.
          await _store.discard(id);
          return null;
        }

        await _sweep();
        return entry;
      } catch (_) {
        return null;
      }
    });
  }

  /// Enregistre ce qu'un delta de synchronisation a appris : une pièce existe,
  /// **sans ses octets**.
  ///
  /// Rend le nombre de lignes retenues. Ce qui est refusé l'est en silence — un
  /// cycle de synchronisation n'a pas à échouer parce qu'une ligne ne
  /// l'intéresse pas : un type que le serveur n'archive pas, une pièce
  /// qu'aucun identifiant ne désigne, une école inconnue.
  ///
  /// Aucune de ces lignes ne pèse au budget ni n'entre dans l'éviction :
  /// [EditiqueCacheEntry.contentSha256] reste nul jusqu'à ce que les octets
  /// arrivent. Et une pièce **déjà détenue** n'est jamais dégradée par un
  /// passage du delta — l'index préserve l'empreinte et le poids qu'il connaît
  /// déjà, sans quoi le premier cycle viderait le cache de ce que la tablette
  /// possède vraiment.
  ///
  /// Ne déclenche aucun balayage : rien n'a été ajouté au disque.
  Future<int> recordKnownDocuments(List<EditiqueCacheEntry> documents) {
    if (documents.isEmpty) return Future.value(0);
    return _exclusive(() async {
      // Même garde qu'à l'écriture d'une pièce : un profil sans droit n'a pas
      // à connaître l'inventaire des pièces de l'établissement.
      if (!await _access.isEntitled()) return 0;
      final now = _now();
      var retained = 0;
      for (final document in documents) {
        try {
          final existing = await _index.findIdentity(document);
          await _index.upsert(
            EditiqueCacheEntry(
              // L'identité locale appartient à ce cache, jamais à l'appelant :
              // une pièce déjà connue garde la sienne — c'est elle qui nomme
              // son fichier chiffré — et une pièce nouvelle en reçoit une.
              id: existing?.id ?? _ids.newId(),
              documentId: document.documentId,
              documentNumber: document.documentNumber,
              docType: document.docType,
              studentId: document.studentId,
              academicYearId: document.academicYearId,
              schoolId: document.schoolId,
              ownerUid: existing?.ownerUid ?? '',
              // Un poids MESURÉ prime sur un poids annoncé : quand la tablette
              // détient les octets, elle sait ce qu'ils pèsent sur SON disque,
              // et c'est cela que le budget compte.
              sizeBytes: (existing?.hasBytes ?? false)
                  ? existing!.sizeBytes
                  : document.sizeBytes,
              // Jamais l'empreinte du serveur : cette colonne dit « la tablette
              // détient ces octets-là ». La renseigner sans les octets ferait
              // croire à une pièce présente, et la première relecture
              // conclurait à un fichier corrompu.
              contentSha256: existing?.contentSha256,
              emittedAt: document.emittedAt,
              createdAt: existing?.createdAt ?? now,
              lastAccessedAt: existing?.lastAccessedAt ?? now,
            ),
          );
          retained++;
        } catch (_) {
          // Ligne refusée par l'index : elle ne concerne pas ce cache.
        }
      }
      return retained;
    });
  }

  // ── Lecture ────────────────────────────────────────────────────────────────

  /// Octets de la pièce portant cet identifiant serveur, `null` si elle n'est
  /// pas en cache ou n'y est plus intègre.
  Future<Uint8List?> readByDocumentId(String documentId) =>
      _read(() => _index.findByDocumentId(documentId));

  /// Octets de la pièce portant ce numéro dans cette école. Repli du régime
  /// AM-5, pour les pièces mises en cache avant que le serveur n'annonce leur
  /// identifiant d'archive.
  Future<Uint8List?> readByDocumentNumber({
    required String schoolId,
    required String documentNumber,
  }) => _read(
    () => _index.findByDocumentNumber(
      schoolId: schoolId,
      documentNumber: documentNumber,
    ),
  );

  Future<Uint8List?> _read(
    Future<EditiqueCacheEntry?> Function() locate,
  ) async {
    try {
      // Les octets restent sur le disque jusqu'à la purge d'ouverture de
      // session : la garde doit donc valoir aussi en lecture, sans quoi un
      // profil sans droit ressortirait les pièces de celui qui l'a précédé.
      if (!await _access.isEntitled()) return null;

      final entry = await locate();
      if (entry == null) return null;

      // Ligne apprise par le delta : la pièce existe, ses octets ne sont pas
      // là. C'est un défaut de cache, jamais une incohérence — et surtout la
      // ligne se garde : l'effacer perdrait une connaissance que le prochain
      // cycle de synchronisation devrait racheter.
      if (!entry.hasBytes) return null;

      final read = await _store.read(entry.id);
      switch (read) {
        // Panne passagère : on n'a rien appris sur la pièce, donc on ne touche
        // à rien. Retomber en ligne est le bon comportement ; détruire ne
        // l'est pas.
        case EditiqueBlobUnavailable():
          return null;

        case EditiqueBlobGone():
          return _forgetIfStillStale(locate);

        case EditiqueBlobFound(:final blob):
          // L'empreinte est la seule chose qui distingue « les octets décrits
          // par cette ligne » de « des octets valides écrits sous ce nom » —
          // le cas d'une écriture concurrente qui a remplacé le fichier avant
          // que sa ligne ne soit à jour.
          if (blob.sha256Hex != entry.contentSha256) {
            return _forgetIfStillStale(locate);
          }
          await _touchQuietly(entry.id);
          return blob.bytes;
      }
    } catch (_) {
      // Une restitution ne fait jamais tomber l'écran qui la demande.
      return null;
    }
  }

  /// Refait le constat **sous le verrou** avant de détruire quoi que ce soit,
  /// et sert la pièce si elle s'avère finalement cohérente.
  ///
  /// La première constatation a lieu hors verrou, donc éventuellement au milieu
  /// d'une réécriture : entre la ligne et le fichier, l'un des deux est
  /// forcément en avance sur l'autre pendant un instant. Détruire sur cette
  /// seule vue reviendrait à effacer une pièce parfaitement valide parce qu'on
  /// l'a regardée au mauvais moment — et à faire réinsérer sa ligne par
  /// l'écriture qui suit, cette fois sans fichier.
  Future<Uint8List?> _forgetIfStillStale(
    Future<EditiqueCacheEntry?> Function() locate,
  ) {
    return _exclusive(() async {
      final entry = await locate();
      if (entry == null) return null;

      final read = await _store.read(entry.id);
      switch (read) {
        case EditiqueBlobUnavailable():
          return null;
        case EditiqueBlobFound(:final blob)
            when blob.sha256Hex == entry.contentSha256:
          // L'écriture concurrente est terminée et tout concorde : il n'y a
          // rien à oublier, et la pièce est due à l'appelant.
          await _touchQuietly(entry.id);
          return blob.bytes;
        case EditiqueBlobFound():
        case EditiqueBlobGone():
          // Fichier d'abord, octets de l'index ensuite : une ligne sans
          // fichier se retélécharge, un fichier sans ligne n'est réclamé par
          // personne. Et si le fichier résiste, l'index garde ses octets — ils
          // sont ce qui le compte au budget.
          //
          // La LIGNE, elle, survit : ce qu'on a appris de la pièce reste vrai
          // même quand ses octets se sont avérés illisibles, et l'effacer la
          // retirerait d'un catalogue que le delta ne repeuplera pas.
          if (await _store.delete(entry.id)) {
            await _maintenance.downgradeToKnown([entry.id]);
          }
          return null;
      }
    });
  }

  /// Marque l'accès **hors du chemin de valeur**.
  ///
  /// Le classement LRU est une heuristique d'éviction ; la pièce, elle, est
  /// déjà déchiffrée et vérifiée en mémoire. Laisser un `UPDATE` refusé — base
  /// pleine, base en cours de fermeture — annuler une restitution rendrait un
  /// défaut de cache pour une pièce présente, et hors ligne cela veut dire
  /// « document indisponible » alors qu'il ne l'est pas.
  Future<void> _touchQuietly(String id) async {
    try {
      await _index.touch(id: id, nowMs: _now());
    } catch (_) {
      // Un accès non enregistré coûte une éviction moins bien choisie. Rien de
      // plus.
    }
  }

  // ── Entretien ──────────────────────────────────────────────────────────────

  /// Ramène le cache sous son budget si celui-ci est franchi. Rend le nombre de
  /// pièces évincées.
  ///
  /// Appelé après chaque écriture ; public pour qu'un démarrage puisse le
  /// rejouer après un budget abaissé.
  Future<int> sweepToBudget() => _exclusive(_sweep);

  Future<int> _sweep() async {
    final total = await _index.totalSizeBytes();
    if (!_policy.needsSweep(total)) return 0;

    final victims = _policy.selectVictims(
      await _maintenance.footprintsByLeastRecentlyUsed(),
    );
    if (victims.isEmpty) return 0;

    // Ne retirer de l'index que ce qui a réellement quitté le disque. Un
    // fichier qui refuse de partir doit **garder** ses octets à l'index : ils
    // sont la seule chose qui le compte au budget et qui le désignera au
    // prochain balayage.
    final freed = <String>[];
    for (final id in victims) {
      if (await _store.delete(id)) freed.add(id);
    }
    if (freed.isEmpty) return 0;
    // Rétrogradées, jamais supprimées : évincer retire des octets, pas une
    // connaissance. Le curseur du delta étant monotone, une ligne effacée ne
    // redescendrait jamais et la pièce disparaîtrait du catalogue pour
    // toujours — alors que le serveur la conserve.
    return _maintenance.downgradeToKnown(freed);
  }

  /// Efface tout ce qui n'appartient pas à l'école courante — la tablette vient
  /// d'être réaffectée (D-7, RG-012-21). Rend les entrées retirées.
  ///
  /// Lève si l'école courante est inconnue : c'est le seul cas où ce cache
  /// refuse d'interpréter plutôt que d'agir, parce que « aucune école courante »
  /// signifierait ici « toutes les écoles sont étrangères », donc un cache vidé
  /// à chaque démarrage à froid.
  Future<List<EditiqueCacheEntry>> purgeForeignSchools(String currentSchoolId) {
    return _exclusive(() async {
      final foreign = await _maintenance.foreignSchoolEntries(currentSchoolId);
      // Les octets d'abord, les lignes ensuite, et seulement celles dont les
      // octets sont réellement partis. Interrompue, la purge laisse des lignes
      // encore étrangères — qu'un prochain appel reprendra — plutôt que des
      // pièces d'un autre établissement que plus rien ne désignerait.
      final removed = <EditiqueCacheEntry>[];
      for (final entry in foreign) {
        if (await _store.delete(entry.id)) removed.add(entry);
      }
      if (removed.isEmpty) return removed;

      await _maintenance.deleteEntries([for (final entry in removed) entry.id]);
      return removed;
    });
  }

  /// Efface le cache **physiquement** : les fichiers, puis la clé qui les
  /// ouvrait, puis l'index. Rend le nombre d'entrées retirées.
  ///
  /// L'ordre est celui qui tient si l'application s'arrête au milieu. La clé
  /// détruite, ce qui resterait du répertoire n'est plus déchiffrable par
  /// personne, et le prochain démarrage l'effacera en constatant une clé neuve.
  /// L'ordre inverse laisserait, lui, des pièces lisibles derrière un index
  /// vide.
  Future<int> purgeAll() {
    return _exclusive(() async {
      await _store.shredAll();
      final removed = await _maintenance.purgeAll();
      return removed.length;
    });
  }

  /// Efface les fichiers que l'index ne désigne plus. Rend leur nombre.
  ///
  /// Contrepartie des purges, qui retirent les lignes avant les fichiers :
  /// interrompues, elles laissent des octets que plus rien ne réclame. À
  /// rejouer au démarrage.
  Future<int> reclaimOrphans() {
    return _exclusive(() async {
      final footprints = await _maintenance.footprintsByLeastRecentlyUsed();
      return _store.reclaimOrphans(
        indexedIds: {for (final footprint in footprints) footprint.id},
      );
    });
  }

  // ── Plomberie ──────────────────────────────────────────────────────────────

  /// File d'attente d'un seul rang : chaque écriture attend la précédente.
  ///
  /// Le `whenComplete` porte un **corps de bloc** et non une flèche : une
  /// flèche rendrait la valeur de `complete()` et, si celle-ci était un
  /// `Future`, la chaîne s'attendrait elle-même.
  Future<T> _exclusive<T>(Future<T> Function() action) {
    final previous = _pending;
    final completer = Completer<void>();
    _pending = completer.future;
    return previous.then((_) => action()).whenComplete(() {
      completer.complete();
    });
  }

  /// Entrée de façade servant uniquement à poser la question d'identité —
  /// identifiant serveur d'abord, numéro dans l'école ensuite. Ses autres
  /// champs ne sont jamais lus.
  EditiqueCacheEntry _identityProbe({
    required String? documentId,
    required String? documentNumber,
    required String docType,
    required String schoolId,
  }) => EditiqueCacheEntry(
    id: '',
    documentId: documentId,
    documentNumber: documentNumber,
    docType: docType,
    schoolId: schoolId,
    sizeBytes: 0,
    contentSha256: '',
    createdAt: 0,
    lastAccessedAt: 0,
  );

  static String? _blankToNull(String? value) =>
      (value == null || value.isEmpty) ? null : value;
}
