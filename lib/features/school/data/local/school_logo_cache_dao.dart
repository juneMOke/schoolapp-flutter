import 'dart:typed_data';

import 'package:sqflite_common/sqlite_api.dart';

/// Les deux variantes de logo qu'une tablette détient.
///
/// ⚠️ Une **troisième** existe côté serveur — `print`, aplatie sur blanc pour
/// les documents — et elle n'a rien à faire ici. C'est pour ça que la contrainte
/// est doublée en SQL sur la table : c'est un invariant de stockage, pas une
/// politique d'appelant.
enum SchoolLogoVariant {
  /// PNG 1 bit, 576×128, logo déjà centré dans les octets. Pour la bande du
  /// ticket thermique.
  thermal('thermal'),

  /// PNG couleur avec alpha, pour l'écran. La transparence est ce qui lui permet
  /// de se poser sur n'importe quel fond sans halo.
  display('display');

  const SchoolLogoVariant(this.dbValue);

  final String dbValue;
}

/// Ce que le cache détient pour une variante : ses octets et leur empreinte.
class CachedSchoolLogo {
  final String sha256;
  final Uint8List bytes;

  const CachedSchoolLogo({required this.sha256, required this.bytes});
}

/// Le cache local du logo de l'école — `school_logo_cache`.
///
/// ## L'empreinte qu'on lit ici est l'ÉTAT, jamais la cible
///
/// Il y a deux empreintes dans le système, et les confondre coûte le logo :
///
/// * celle de `ref_school`, descendue par le lot référentiel, dit **ce que
///   l'école a** ;
/// * celle de cette table dit **ce que la tablette détient**.
///
/// Le tirage conditionnel se construit **exclusivement** sur la seconde. Un
/// `If-None-Match` bâti sur la première produit un `304` **définitif** après un
/// tirage raté : le serveur répond « rien de neuf » sur une empreinte qu'on n'a
/// pas, et les octets n'arrivent jamais. L'état est stable, silencieux, et sans
/// erreur à montrer. Ligne absente ⇒ **aucun en-tête conditionnel**.
class SchoolLogoCacheDao {
  final Database _db;

  const SchoolLogoCacheDao(this._db);

  static const String _table = 'school_logo_cache';

  /// L'empreinte détenue pour cette variante, `null` si rien n'est en cache.
  ///
  /// ⚠️ **Lit `sha256` SEUL, jamais `*`.** Les octets vivent en pages de
  /// débordement : ne pas les nommer, c'est ne pas les charger. Cette lecture a
  /// lieu à chaque comparaison d'invalidation, la lecture des octets une fois
  /// par rendu.
  Future<String?> findSha(String schoolId, SchoolLogoVariant variant) async {
    final rows = await _db.query(
      _table,
      columns: const ['sha256'],
      where: 'school_id = ? AND variant = ?',
      whereArgs: [schoolId, variant.dbValue],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['sha256'] as String?;
  }

  /// Les octets détenus, avec leur empreinte. `null` si rien n'est en cache.
  Future<CachedSchoolLogo?> find(
    String schoolId,
    SchoolLogoVariant variant,
  ) async {
    final rows = await _db.query(
      _table,
      columns: const ['sha256', 'bytes'],
      where: 'school_id = ? AND variant = ?',
      whereArgs: [schoolId, variant.dbValue],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CachedSchoolLogo(
      sha256: rows.first['sha256'] as String,
      bytes: rows.first['bytes'] as Uint8List,
    );
  }

  /// Pose ou remplace le logo d'une variante.
  ///
  /// ⚠️ **La ligne est écrite ENTIÈRE, jamais par morceaux.** Un
  /// `ConflictAlgorithm.replace` avec une carte partielle remettrait à `NULL`
  /// les colonnes omises sans rien signaler — c'est exactement ce qui a vidé
  /// `generated_documents.pdf_blob`, dont le palier v21 constate qu'elle était
  /// « vide par construction ».
  ///
  /// Empreinte et octets partent donc **ensemble**. Écrire l'une sans les autres
  /// rejouerait le piège du `304` : la tablette annoncerait détenir une image
  /// qu'elle n'a pas.
  Future<void> put({
    required String schoolId,
    required SchoolLogoVariant variant,
    required String sha256,
    required Uint8List bytes,
    required DateTime fetchedAt,
  }) => _db.insert(_table, {
    'school_id': schoolId,
    'variant': variant.dbValue,
    'sha256': sha256,
    'bytes': bytes,
    'fetched_at': fetchedAt.millisecondsSinceEpoch,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  /// Retire le logo d'une variante — l'école n'en a plus, ou le serveur ne le
  /// sert plus.
  ///
  /// Effacer plutôt que garder : une école qui retire son sceau continuerait
  /// sinon de l'imprimer sur ses tickets, indéfiniment et hors ligne.
  Future<int> delete(String schoolId, SchoolLogoVariant variant) => _db.delete(
    _table,
    where: 'school_id = ? AND variant = ?',
    whereArgs: [schoolId, variant.dbValue],
  );

  /// Évacue les logos de toute école autre que [schoolId].
  ///
  /// La table est clavetée par école, donc rien ne se mélange jamais : une
  /// tablette qui change d'établissement ne servira pas le sceau du précédent.
  /// Ce nettoyage ne corrige donc aucun défaut, il récupère quelques kilo-octets
  /// — et il reste utile tant que la base est partagée entre écoles, ce que le
  /// plan multi-école se propose justement de défaire.
  Future<int> deleteForeignSchools(String schoolId) =>
      _db.delete(_table, where: 'school_id <> ?', whereArgs: [schoolId]);
}
