import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/evolution_bucket.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/evolution_granularity.dart';

/// Le rythme d'inscription : une série de barres, et l'axe qu'elles couvrent.
class EnrollmentEvolution extends Equatable {
  final EvolutionGranularity granularity;

  /// Position de la barre en cours **dans le tableau rendu**.
  ///
  /// Ce n'est pas un rang de date : une barre de tête « hors axe » décale tout
  /// d'un cran. Il se lit, il ne se recalcule pas.
  final int currentBucketIndex;

  /// Étendue réellement tracée. **Ce n'est pas la fenêtre comptée** : sur
  /// l'onglet du jour, l'axe couvre cinq jours (« un seul jour ne se lit pas
  /// seul ») quand les chiffres clés en comptent un. Ne jamais s'en servir
  /// pour légender les cartes.
  final DateTime? axisStart;
  final DateTime? axisEnd;

  final List<EvolutionBucket> buckets;

  const EnrollmentEvolution({
    required this.granularity,
    required this.currentBucketIndex,
    this.axisStart,
    this.axisEnd,
    required this.buckets,
  });

  @override
  List<Object?> get props => [
    granularity,
    currentBucketIndex,
    axisStart,
    axisEnd,
    buckets,
  ];
}
