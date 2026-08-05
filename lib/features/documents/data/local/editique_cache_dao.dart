import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';

/// Table portant l'index du cache de restitution éditique. Partagée par les
/// deux DAO qui la servent, pour qu'aucun des deux ne puisse en désigner une
/// autre.
const String kEditiqueCacheTable = 'editique_cache_entries';

/// Vie normale de l'**index** du cache de restitution éditique (ADR-012 D-2) :
/// retrouver une pièce, mesurer ce que le cache pèse, enregistrer un accès.
///
/// Ne lit ni n'écrit jamais un octet de PDF : les pièces scellées vivent dans
/// des fichiers chiffrés hors base. Tant que ce magasin d'octets n'existe pas
/// (lot L3.3), l'index se manipule donc **à vide** — ce qui est précisément
/// l'intérêt de le poser d'abord.
///
/// Le retrait de pièces — balayage LRU, effacement de D-7 — appartient à
/// `EditiqueCacheMaintenanceDao` : détruire de la donnée locale n'a ni les
/// mêmes appelants ni les mêmes conséquences que la consulter.
///
/// ## Échec de mise en cache
///
/// Jamais fatal. Une pièce qu'on n'a pas su cacher reste servie en ligne ;
/// faire échouer une émission parce que son cache a échoué inverserait les
/// priorités.
class EditiqueCacheDao {
  final DatabaseExecutor _db;

  const EditiqueCacheDao(this._db);

  // ── Lecture ────────────────────────────────────────────────────────────────

  /// Entrée portant cet identifiant serveur, `null` si la pièce n'est pas en
  /// cache.
  Future<EditiqueCacheEntry?> findByDocumentId(String documentId) async {
    if (documentId.isEmpty) return null;
    final rows = await _db.query(
      kEditiqueCacheTable,
      where: 'document_id = ?',
      whereArgs: [documentId],
      limit: 1,
    );
    return rows.isEmpty ? null : EditiqueCacheEntry.fromMap(rows.first);
  }

  /// Entrée portant ce numéro de pièce dans cette école. Repli du régime AM-5,
  /// tant que l'émission ne rend pas d'identifiant.
  Future<EditiqueCacheEntry?> findByDocumentNumber({
    required String schoolId,
    required String documentNumber,
  }) async {
    if (documentNumber.isEmpty) return null;
    final rows = await _db.query(
      kEditiqueCacheTable,
      where: 'school_id = ? AND document_number = ?',
      whereArgs: [schoolId, documentNumber],
      limit: 1,
    );
    return rows.isEmpty ? null : EditiqueCacheEntry.fromMap(rows.first);
  }

  /// Pièces en cache d'un élève, de la plus récemment **émise** à la plus
  /// ancienne — l'ordre du serveur, pas celui de la mise en cache.
  ///
  /// [academicYearId] est facultatif : le catalogue raisonne par année,
  /// l'historique d'un élève non.
  Future<List<EditiqueCacheEntry>> listForStudent({
    required String schoolId,
    required String studentId,
    String? academicYearId,
  }) async {
    final where = StringBuffer('school_id = ? AND student_id = ?');
    final args = <Object?>[schoolId, studentId];
    if (academicYearId != null && academicYearId.isNotEmpty) {
      where.write(' AND academic_year_id = ?');
      args.add(academicYearId);
    }

    final rows = await _db.query(
      kEditiqueCacheTable,
      where: where.toString(),
      whereArgs: args,
      // Les entrées sans date d'émission connue passent en dernier (SQLite
      // ordonne NULL en premier en ASC, donc en dernier en DESC).
      orderBy: 'emitted_at DESC, created_at DESC, id DESC',
    );
    return rows.map(EditiqueCacheEntry.fromMap).toList(growable: false);
  }

  // ── Mesure ─────────────────────────────────────────────────────────────────

  /// Poids total du cache, en octets, **sans lire un seul fichier**.
  ///
  /// Ne compte que les pièces réellement **détenues** : une ligne apprise par
  /// le delta décrit une pièce qui n'occupe rien sur ce disque. La compter
  /// ferait balayer l'éviction pour libérer une place déjà libre, et évincer de
  /// vraies pièces pour rien.
  ///
  /// Non scopé par défaut : le budget est une propriété du disque de la
  /// tablette. [schoolId] ne sert qu'à mesurer ce que coûterait une purge.
  Future<int> totalSizeBytes({String? schoolId}) async {
    final scoped = schoolId != null && schoolId.isNotEmpty;
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM(size_bytes), 0) AS total FROM $kEditiqueCacheTable '
      'WHERE content_sha256 IS NOT NULL'
      '${scoped ? ' AND school_id = ?' : ''}',
      scoped ? [schoolId] : null,
    );
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  /// Poids par année scolaire, pour une école. Clé de **mesure** et de
  /// libération manuelle éventuelle — jamais un déclencheur de purge (AM-8 :
  /// la purge calendaire est supprimée, sa falaise tomberait au 1er septembre,
  /// pendant les réinscriptions). Les entrées sans année connue sont regroupées
  /// sous la chaîne vide plutôt que perdues.
  Future<Map<String, int>> sizeBytesByAcademicYear(String schoolId) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(academic_year_id, ?) AS year, '
      'COALESCE(SUM(size_bytes), 0) AS total '
      'FROM $kEditiqueCacheTable WHERE school_id = ? GROUP BY year',
      ['', schoolId],
    );
    return {
      for (final row in rows)
        (row['year'] as String?) ?? '': (row['total'] as num?)?.toInt() ?? 0,
    };
  }

  Future<int> count() async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM $kEditiqueCacheTable',
    );
    return (rows.first['c'] as num?)?.toInt() ?? 0;
  }

  // ── Écriture ───────────────────────────────────────────────────────────────

  /// Enregistre ou met à jour une entrée d'index.
  ///
  /// **Jamais `ConflictAlgorithm.replace`** : `replace` supprime puis réinsère,
  /// ce qui ferait perdre la clé locale de l'entrée — donc le nom de son
  /// fichier chiffré, donc le fichier lui-même, transformé en orphelin — ainsi
  /// que sa date de mise en cache et sa place LRU. On met donc à jour la ligne
  /// existante quand il y en a une, et on n'insère que sinon.
  ///
  /// Une entrée déjà indexée par numéro se voit **compléter** son
  /// `document_id` le jour où le serveur l'expose (lot B2), sans changer
  /// d'identité locale.
  ///
  /// Lève si le type n'est pas archivé côté serveur, ou si l'entrée n'est
  /// adressable par aucun des deux identifiants : ce sont des fautes
  /// d'appelant, que la contrainte `CHECK` du schéma refuserait de toute façon,
  /// avec un message bien moins lisible.
  Future<void> upsert(EditiqueCacheEntry entry) async {
    if (!EditiqueCacheEntry.isCacheableDocType(entry.docType)) {
      throw ArgumentError.value(
        entry.docType,
        'docType',
        'Type non archivé par le serveur : une pièce horodatée mise en cache '
            'en serait l\'unique exemplaire, et l\'éviction la détruirait',
      );
    }
    if (!entry.isAddressable) {
      throw ArgumentError.value(
        entry.id,
        'entry',
        'Entrée sans identifiant ni numéro : son fichier occuperait le budget '
            'sans qu\'aucune demande ne puisse le désigner',
      );
    }

    // Deux normalisations, chacune pour une raison précise.
    //
    // Le type est stocké dans sa forme canonique : la garde Dart tolère la
    // casse (règle de parsing), la contrainte SQL non (règle de stockage).
    // Sans cela, un `rc` traverserait la première pour se faire refuser par la
    // seconde, avec un message illisible.
    //
    // Un identifiant vide devient NULL : « inconnu » doit s'écrire NULL, seule
    // valeur que les index uniques considèrent comme distincte d'elle-même.
    // Stockée telle quelle, une chaîne vide ferait entrer en collision deux
    // pièces dont on ignore simplement l'identifiant.
    final documentId = _nullIfEmpty(entry.documentId);
    final documentNumber = _nullIfEmpty(entry.documentNumber);
    final payload = entry.toMap()
      ..['doc_type'] = entry.docType.toUpperCase()
      ..['document_id'] = documentId
      ..['document_number'] = documentNumber;

    final existing = await findIdentity(entry);
    if (existing == null) {
      await _db.insert(kEditiqueCacheTable, payload);
      return;
    }

    final values = payload
      ..remove('id')
      ..remove('created_at');

    // **Ne jamais effacer une métadonnée connue avec une inconnue.** Les deux
    // sources qui alimentent cet index n'en savent pas les mêmes choses : une
    // émission ne connaît souvent que l'objet qu'elle vient de produire — une
    // attestation est demandée par dossier, un reçu par versement, ni l'un ni
    // l'autre ne nomme l'élève ni l'année — là où le listing serveur les
    // connaît tous les deux. Écrire aveuglément ferait donc perdre, à chaque
    // ré-émission, l'attribution qu'un pull avait renseignée.
    final known = existing.toMap();
    for (final field in const [
      'document_id',
      'document_number',
      'student_id',
      'academic_year_id',
      'emitted_at',
      // `content_sha256` est dans cette liste pour une raison qui vaut des
      // documents : le delta de synchronisation ne connaît QUE des métadonnées.
      // S'il écrasait l'empreinte d'une pièce détenue, la relecture suivante
      // comparerait le fichier à une empreinte absente, conclurait à une pièce
      // corrompue, et effacerait le fichier ET sa ligne. Un cycle de pull
      // viderait le cache de ce que la tablette possède vraiment.
      'content_sha256',
    ]) {
      values[field] ??= known[field];
    }
    // Même règle pour le poids : « 0 » est l'inconnu de cette colonne, et une
    // pièce détenue en pèse toujours plus.
    if (entry.sizeBytes <= 0 && existing.sizeBytes > 0) {
      values['size_bytes'] = existing.sizeBytes;
    }
    // `owner_uid` suit la même règle, à ceci près que son « inconnu » s'écrit
    // chaîne vide : la colonne est NOT NULL.
    if (entry.ownerUid.isEmpty && existing.ownerUid.isNotEmpty) {
      values['owner_uid'] = existing.ownerUid;
    }
    await _db.update(
      kEditiqueCacheTable,
      values,
      where: 'id = ?',
      whereArgs: [existing.id],
    );
  }

  /// Marque un accès : c'est la SEULE entrée du classement LRU.
  ///
  /// Doit être appelée à chaque **restitution**, pas seulement à l'écriture —
  /// sans cela le cache évincerait par ancienneté de mise en cache, et la pièce
  /// qu'on ressort tous les jours serait la première à partir.
  Future<void> touch({required String id, required int nowMs}) async {
    await _db.update(
      kEditiqueCacheTable,
      {'last_accessed_at': nowMs},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static String? _nullIfEmpty(String? value) =>
      (value == null || value.isEmpty) ? null : value;

  /// Ligne existante correspondant à l'identité de [entry] : d'abord
  /// l'identifiant serveur, puis le numéro dans l'école.
  ///
  /// Publique parce que le magasin d'octets doit poser **exactement** la même
  /// question avant d'écrire un fichier : c'est la clé locale de la ligne
  /// existante qui nomme ce fichier, et [upsert] la conserve. Écrire sous une
  /// clé fraîche laisserait le fichier de la version précédente sur le disque,
  /// orphelin, pendant que la ligne continuerait de désigner son ancien nom.
  Future<EditiqueCacheEntry?> findIdentity(EditiqueCacheEntry entry) async {
    final documentId = entry.documentId;
    if (documentId != null && documentId.isNotEmpty) {
      final byId = await findByDocumentId(documentId);
      if (byId != null) return byId;
    }
    final number = entry.documentNumber;
    if (number != null && number.isNotEmpty) {
      return findByDocumentNumber(
        schoolId: entry.schoolId,
        documentNumber: number,
      );
    }
    return null;
  }
}
