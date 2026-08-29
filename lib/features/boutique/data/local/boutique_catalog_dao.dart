import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_local_models.dart';

/// Le catalogue boutique en base locale : remplacement en bloc à l'arrivée du
/// bundle, lecture pour l'écran de caisse.
///
/// **Remplacement, pas delta.** Le catalogue descend dans le bundle référentiel
/// (ADR-020, décision F4) : il n'y a ni curseur ni version à arbitrer, et
/// l'absence d'une ligne dans le bundle **est** l'ordre de la retirer. Un
/// article retiré de la vente côté serveur ne doit pas rester vendable au
/// guichet.
class BoutiqueCatalogDao {
  final Database _db;

  const BoutiqueCatalogDao(this._db);

  /// Taille de lot des purges `id IN (…)` — bornée bien en-deçà de
  /// `SQLITE_MAX_VARIABLE_NUMBER` (999 sur les SQLite anciens d'Android 10).
  ///
  /// Un `id NOT IN (…)` non borné lie un paramètre par article conservé et
  /// dépasse la limite dès qu'un catalogue devient gros — ce qui ferait lever
  /// l'apply, donc **figerait le curseur référentiel** et rejouerait le pull en
  /// boucle.
  static const int _deleteChunkSize = 500;

  /// Remplace le catalogue des années couvertes par le bundle, **scopé école**.
  ///
  /// [academicYearIds] vide → aucune purge, upsert seul. C'est la porte de
  /// sortie du caviardage : quand le serveur n'a pas servi la section (droit
  /// `boutique.catalog.read` absent), l'appelant ne fournit aucune année, et le
  /// catalogue local reste intact. Une section **présente mais vide** est, elle,
  /// un ordre de purge légitime — c'est l'école qui n'a pas d'article.
  ///
  /// Le scope école n'est pas décoratif : la conception « une tablette, une
  /// école » a déjà produit dix flux à curseur nu, et purger sans lui effacerait
  /// le catalogue de l'autre établissement sur une tablette partagée.
  Future<void> replaceArticlesForYears(
    List<BoutiqueArticleLocalModel> articles, {
    required String schoolId,
    required List<String> academicYearIds,
  }) async {
    await _db.transaction((txn) async {
      if (academicYearIds.isNotEmpty) {
        final years = List.filled(academicYearIds.length, '?').join(', ');
        final existing = await txn.query(
          'ref_boutique_articles',
          columns: ['id'],
          where: 'school_id = ? AND academic_year_id IN ($years)',
          whereArgs: [schoolId, ...academicYearIds],
        );
        final keepIds = {for (final a in articles) a.id};
        final staleIds = [
          for (final row in existing)
            if (!keepIds.contains(row['id'] as String)) row['id'] as String,
        ];
        for (var i = 0; i < staleIds.length; i += _deleteChunkSize) {
          final end = i + _deleteChunkSize < staleIds.length
              ? i + _deleteChunkSize
              : staleIds.length;
          final chunk = staleIds.sublist(i, end);
          final marks = List.filled(chunk.length, '?').join(', ');
          // La grille d'abord : sans clé étrangère (aucune n'existe entre ces
          // deux tables), la supprimer après laisserait des cases orphelines si
          // la transaction s'interrompait entre les deux — et une case
          // orpheline se rattacherait au prochain article de même id.
          await txn.delete(
            'ref_boutique_article_level_prices',
            where: 'article_id IN ($marks)',
            whereArgs: chunk,
          );
          await txn.delete(
            'ref_boutique_articles',
            where: 'id IN ($marks)',
            whereArgs: chunk,
          );
        }
      }

      final batch = txn.batch();
      for (final article in articles) {
        batch.insert(
          'ref_boutique_articles',
          article.toMap(schoolId: schoolId),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        // La grille est remplacée case par case : un simple upsert laisserait
        // vivre une case retirée du bundle, et la caisse vendrait à un niveau
        // dont le serveur ne veut plus.
        batch.delete(
          'ref_boutique_article_level_prices',
          where: 'article_id = ?',
          whereArgs: [article.id],
        );
        for (final entry in article.levelPrices.entries) {
          batch.insert(
            'ref_boutique_article_level_prices',
            {
              'article_id': article.id,
              'school_level_id': entry.key,
              'price_in_cents': entry.value,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      await batch.commit(noResult: true);
    });
  }

  /// Le catalogue vendable d'une année, grille comprise.
  ///
  /// Deux requêtes et une jointure en Dart, jamais un `LEFT JOIN` : la jointure
  /// duplique l'article autant de fois qu'il a de cases, et le recomposer
  /// coûterait le même travail après avoir transporté n fois chaque libellé.
  ///
  /// **Ne trie pas.** L'ordre d'affichage est celui de la famille, que le
  /// domaine porte (`ArticleFamily` déclare son ordre) — le SQL ne connaît que
  /// l'alphabet, et trier ici donnerait `BULT, CHEM, ECUS, JDCL…`, que personne
  /// ne parcourt à midi avec une file d'attente.
  Future<List<BoutiqueArticleLocalModel>> articlesOfYear({
    required String schoolId,
    required String academicYearId,
  }) async {
    final rows = await _db.query(
      'ref_boutique_articles',
      where: 'school_id = ? AND academic_year_id = ?',
      whereArgs: [schoolId, academicYearId],
    );
    if (rows.isEmpty) return const [];

    // Bornée aux articles réellement chargés, par lots : la table porte les
    // grilles de TOUTES les années et de toutes les écoles de la tablette, et
    // les lire en entier ferait grossir chaque ouverture de la caisse avec
    // l'historique. Le découpage respecte la même limite de variables liées que
    // la purge.
    final articleIds = [for (final row in rows) row['id'] as String];
    final gridByArticle = <String, Map<String, int>>{};
    for (var i = 0; i < articleIds.length; i += _deleteChunkSize) {
      final end = i + _deleteChunkSize < articleIds.length
          ? i + _deleteChunkSize
          : articleIds.length;
      final chunk = articleIds.sublist(i, end);
      final priceRows = await _db.query(
        'ref_boutique_article_level_prices',
        where: 'article_id IN (${List.filled(chunk.length, '?').join(', ')})',
        whereArgs: chunk,
      );
      for (final row in priceRows) {
        final articleId = row['article_id'] as String;
        gridByArticle.putIfAbsent(
          articleId,
          () => <String, int>{},
        )[row['school_level_id'] as String] = (row['price_in_cents'] as num)
            .toInt();
      }
    }

    return [
      for (final row in rows)
        BoutiqueArticleLocalModel.fromMap(
          row,
          levelPrices: gridByArticle[row['id'] as String] ?? const {},
        ),
    ];
  }

  /// Nombre d'articles connus pour cette école et cette année.
  ///
  /// Sert à distinguer les deux vides de l'écran — « la boutique n'a pas encore
  /// d'article » d'un catalogue simplement pas encore descendu. La distinction
  /// « non communiqué » (droit absent), elle, ne se lit pas ici : elle vient du
  /// bundle, pas de la base.
  Future<int> countArticles({
    required String schoolId,
    required String academicYearId,
  }) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM ref_boutique_articles '
      'WHERE school_id = ? AND academic_year_id = ?',
      [schoolId, academicYearId],
    );
    return (rows.first['c'] as num?)?.toInt() ?? 0;
  }
}
