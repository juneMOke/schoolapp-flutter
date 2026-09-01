import 'package:school_app_flutter/features/finance/data/models/finance_recovery_response_model/finance_evolution_bucket_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/finance_evolution.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/finance_evolution_granularity.dart';

class FinanceEvolutionModel {
  final String granularity;
  final int currentBucketIndex;
  final List<FinanceEvolutionBucketModel> buckets;

  const FinanceEvolutionModel({
    required this.granularity,
    required this.currentBucketIndex,
    required this.buckets,
  });

  /// L'axe **vide** est une lecture valide : la section est un ornement du
  /// tableau de bord, pas son chiffre. Un axe absent rend un graphique vide,
  /// jamais une erreur qui emporterait les KPI avec elle.
  factory FinanceEvolutionModel.fromJson(Map<String, dynamic> json) {
    return FinanceEvolutionModel(
      granularity: ((json['granularity'] as String?) ?? '').trim(),
      // `-1` est la valeur que le serveur lui-même envoie quand aujourd'hui
      // tombe hors de l'année : aucun compartiment n'est courant.
      currentBucketIndex: (json['currentBucketIndex'] as num?)?.toInt() ?? -1,
      buckets: [
        for (final raw in (json['buckets'] as List<dynamic>? ?? const []))
          if (raw is Map<String, dynamic>)
            FinanceEvolutionBucketModel.fromJson(raw),
      ],
    );
  }

  /// L'axe qu'on rend quand le serveur n'envoie pas de section.
  static const FinanceEvolutionModel empty = FinanceEvolutionModel(
    granularity: 'month',
    currentBucketIndex: -1,
    buckets: [],
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'granularity': granularity,
    'currentBucketIndex': currentBucketIndex,
    'buckets': buckets.map((bucket) => bucket.toJson()).toList(growable: false),
  };

  FinanceEvolution toEntity() => FinanceEvolution(
    granularity: _parseGranularity(granularity),
    currentBucketIndex: currentBucketIndex,
    buckets: buckets.map((bucket) => bucket.toEntity()).toList(growable: false),
  );

  /// Le recouvrement ne rend que `month`. Les deux autres valeurs restent
  /// lisibles, et l'inconnue retombe sur `month` : un grain qu'on ne
  /// reconnaîtrait pas ne doit pas faire échouer la lecture du tableau de bord.
  FinanceEvolutionGranularity _parseGranularity(String value) =>
      switch (value) {
        'week' => FinanceEvolutionGranularity.week,
        'day' => FinanceEvolutionGranularity.day,
        _ => FinanceEvolutionGranularity.month,
      };
}
