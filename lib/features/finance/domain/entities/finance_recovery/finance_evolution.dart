import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/finance_evolution_bucket.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/finance_evolution_granularity.dart';

/// **Quand** l'argent est rentré, mois par mois — et non **combien**.
///
/// ⚠️ **Ce n'est pas un second total.** Un versement rattaché à l'année mais
/// daté hors de sa fenêtre de douze mois compte dans `kpis.collected` sans
/// apparaître sur l'axe : la somme des compartiments peut être **inférieure**
/// au KPI. Ne jamais s'en servir comme contrôle de cohérence — le KPI répond
/// « combien a été recouvré sur cette année », la courbe répond « quand ».
class FinanceEvolution extends Equatable {
  final FinanceEvolutionGranularity granularity;

  /// Index du compartiment en cours, `-1` si aujourd'hui tombe hors de l'année.
  final int currentBucketIndex;

  /// Douze compartiments, dans l'ordre, à partir du mois où **l'année scolaire
  /// commence** — pas septembre par convention : une école qui ouvre en octobre
  /// reçoit `"2025-10"` en premier.
  final List<FinanceEvolutionBucket> buckets;

  const FinanceEvolution({
    required this.granularity,
    required this.currentBucketIndex,
    required this.buckets,
  });

  @override
  List<Object?> get props => [granularity, currentBucketIndex, buckets];
}
