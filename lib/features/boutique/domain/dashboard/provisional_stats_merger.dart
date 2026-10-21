import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/features/boutique/domain/dashboard/stats_bucket_keys.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_currency_stats.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_family_amount.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats_bucket.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/provisional_sale_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/provisional_sales.dart';

/// Ajoute aux chiffres du serveur les tickets que ce poste a encaissés et que
/// le serveur ne connaît pas encore.
///
/// **Ajoutés, jamais substitués** : le serveur compte l'école entière, le poste
/// ne connaît de provisoire que le sien. Les compteurs, les recettes, la série
/// et les familles les absorbent ; **le top des articles, non** — un classement
/// se recalcule sur la liste complète, que le client n'a pas, et un sixième
/// article remonté à tort serait pire qu'un compte légèrement en retard.
///
/// ⚠️ Fenêtre de double compte, acceptée en V1 : une vente poussée dont l'ACK
/// s'est perdu est comptée par le serveur ET encore provisoire ici jusqu'au
/// rejeu. Rare et bornée ; le serveur ne pourrait l'éviter qu'en renvoyant la
/// liste des identifiants de la fenêtre.
abstract final class ProvisionalStatsMerger {
  static BoutiqueStats merge(
    BoutiqueStats stats,
    ProvisionalSales provisional,
  ) {
    // Seules les lignes de LA fenêtre comptée par le serveur : une photo de
    // cache d'hier ne doit pas absorber le ticket d'aujourd'hui.
    final lines = [
      for (final line in provisional.lines)
        if (stats.window.containsInstant(line.soldAt)) line,
    ];
    if (lines.isEmpty) return stats;

    final inWindow = ProvisionalSales(lines);
    final byCurrency = <String, List<ProvisionalSaleLine>>{};
    for (final line in lines) {
      byCurrency
          .putIfAbsent(CurrencyCode.normalize(line.currency), () => [])
          .add(line);
    }

    final blocks = [
      for (final block in stats.byCurrency)
        _mergeBlock(stats, block, byCurrency.remove(block.currency)),
      // Une devise que le serveur n'a pas vue sur la fenêtre : un bloc naît,
      // avec sa série dense, pour que la barre du jour ait où se poser.
      for (final entry in byCurrency.entries)
        _mergeBlock(
          stats,
          BoutiqueCurrencyStats(
            currency: entry.key,
            revenue: 0,
            previousRevenue: 0,
            saleCount: 0,
            previousSaleCount: 0,
            buckets: [
              for (final key in StatsBucketKeys.denseKeys(
                stats.window,
                stats.granularity,
              ))
                BoutiqueStatsBucket(key: key, total: 0),
            ],
          ),
          entry.value,
        ),
    ]..sort((a, b) => a.currency.compareTo(b.currency));

    return stats.copyWith(
      saleCount: stats.saleCount + inWindow.saleCount,
      articleCount: stats.articleCount + inWindow.articleCount,
      byCurrency: blocks,
    );
  }

  static BoutiqueCurrencyStats _mergeBlock(
    BoutiqueStats stats,
    BoutiqueCurrencyStats block,
    List<ProvisionalSaleLine>? lines,
  ) {
    if (lines == null || lines.isEmpty) return block;

    final byKey = <String, int>{};
    for (final line in lines) {
      final key = StatsBucketKeys.of(line.soldAt, stats.granularity);
      byKey[key] = (byKey[key] ?? 0) + line.lineTotal;
    }

    return block.copyWith(
      revenue: block.revenue + lines.fold(0, (sum, l) => sum + l.lineTotal),
      saleCount: block.saleCount + ProvisionalSales(lines).saleCount,
      // Un seau absent de la série (horloge du poste hors fenêtre serveur) est
      // ignoré plutôt qu'ajouté en queue : il casserait l'ordre de l'axe. Le
      // total, lui, l'a compté.
      buckets: [
        for (final bucket in block.buckets) bucket.plus(byKey[bucket.key] ?? 0),
      ],
      families: _mergeFamilies(block.families, lines),
    );
  }

  static List<BoutiqueFamilyAmount> _mergeFamilies(
    List<BoutiqueFamilyAmount> families,
    List<ProvisionalSaleLine> lines,
  ) {
    final merged = <ArticleFamily?, BoutiqueFamilyAmount>{
      for (final family in families) family.family: family,
    };
    for (final line in lines) {
      final current =
          merged[line.family] ??
          BoutiqueFamilyAmount(family: line.family, amount: 0, quantity: 0);
      merged[line.family] = current.plus(
        amount: line.lineTotal,
        quantity: line.quantity,
      );
    }
    // L'ordre du catalogue, comme le serveur ; l'inconnu en dernier.
    return merged.values.toList()..sort(
      (a, b) => (a.family?.index ?? ArticleFamily.values.length).compareTo(
        b.family?.index ?? ArticleFamily.values.length,
      ),
    );
  }
}
