import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_family_amount.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats_bucket.dart';

/// Ce que la boutique a vendu **dans une devise de catalogue**.
///
/// Vendu, pas perçu : les montants sont ceux des lignes. Ce qui est entré dans
/// le tiroir, devise reçue, est la question de la caisse Finances — mêler les
/// deux reproduirait le défaut que `finance-stats/till` a corrigé.
class BoutiqueCurrencyStats extends Equatable {
  final String currency;

  /// En centimes, Σ des lignes de la fenêtre.
  final int revenue;
  final int previousRevenue;

  /// Les ventes ayant **au moins une ligne** dans cette devise. Une vente qui
  /// mêle dollars et francs compte dans les deux blocs : c'est ce qui rend le
  /// panier moyen d'une devise juste.
  final int saleCount;
  final int previousSaleCount;

  final List<BoutiqueStatsBucket> buckets;

  /// Dans l'ordre du catalogue ; une famille sans vente est absente.
  final List<BoutiqueFamilyAmount> families;

  const BoutiqueCurrencyStats({
    required this.currency,
    required this.revenue,
    required this.previousRevenue,
    required this.saleCount,
    required this.previousSaleCount,
    this.buckets = const [],
    this.families = const [],
  });

  /// Le panier moyen **de cette devise**, en centimes arrondis au plus proche.
  ///
  /// Un panier moyen qui additionnerait francs et dollars n'existe pas. `null`
  /// sans vente : zéro dirait « des paniers vides », ce qui n'a pas eu lieu.
  int? get averageBasket =>
      saleCount == 0 ? null : (revenue / saleCount).round();

  int? get previousAverageBasket => previousSaleCount == 0
      ? null
      : (previousRevenue / previousSaleCount).round();

  BoutiqueCurrencyStats copyWith({
    int? revenue,
    int? saleCount,
    List<BoutiqueStatsBucket>? buckets,
    List<BoutiqueFamilyAmount>? families,
  }) => BoutiqueCurrencyStats(
    currency: currency,
    revenue: revenue ?? this.revenue,
    previousRevenue: previousRevenue,
    saleCount: saleCount ?? this.saleCount,
    previousSaleCount: previousSaleCount,
    buckets: buckets ?? this.buckets,
    families: families ?? this.families,
  );

  @override
  List<Object?> get props => [
    currency,
    revenue,
    previousRevenue,
    saleCount,
    previousSaleCount,
    buckets,
    families,
  ];
}
