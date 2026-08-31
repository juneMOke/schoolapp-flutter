import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/fee_type_distribution.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/finance_evolution.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/finance_kpis.dart';

/// Le tableau de bord financier **d'une seule devise**.
///
/// Autonome à dessein : un écran qui n'affiche qu'une unité lit un bloc et n'a
/// besoin de rien d'autre. C'est ce qui rend le rendu mono-devise identique à
/// ce qu'il était avant que les indicateurs ne descendent d'un niveau.
///
/// **Aucune conversion, jamais.** Convertir demanderait un taux ; un taux bouge,
/// et un chiffre de pilotage qui bouge alors qu'aucun argent n'a bougé ne se lit
/// plus. Les blocs se regardent côte à côte, ils ne s'additionnent pas.
class FinanceCurrencyBlock extends Equatable {
  final String currency;
  final FinanceKpis kpis;

  /// **Même axe du temps dans tous les blocs** — granularité, clés de compartiment
  /// et `currentBucketIndex` identiques — pour que deux devises se comparent
  /// compartiment par compartiment. Seules les valeurs diffèrent.
  ///
  /// Ce qui autorise à **empiler** les graphiques, jamais à les superposer sur un
  /// même axe vertical : l'écart d'échelle entre le franc et le dollar est de
  /// ×2 800, et une courbe écraserait l'autre.
  final FinanceEvolution evolution;

  /// Seuls les postes facturés ou encaissés **dans cette devise**. Un même code
  /// facturé dans deux unités apparaît dans les deux blocs, avec son montant
  /// propre à chacun — ce n'est pas un doublon.
  final FeeTypeDistribution distributionByFeeType;

  const FinanceCurrencyBlock({
    required this.currency,
    required this.kpis,
    required this.evolution,
    required this.distributionByFeeType,
  });

  @override
  List<Object?> get props => [currency, kpis, evolution, distributionByFeeType];
}
