import 'package:equatable/equatable.dart';

/// Bilan d'un pull des cours (`AcademicsCoursPullRepositoryImpl`, ressource
/// unique scopée enseignant — DF-K) ou du bundle `grades-referential`
/// (`GradesReferentialPullRepositoryImpl`, ETag non paginé). [notModified]
/// vrai ⟺ rien de nouveau à appliquer ; [bootstrapComplete] vrai ⟺ le premier
/// passage complet a bouclé sans échec.
class CoursPullOutcome extends Equatable {
  final int upserted;
  final bool notModified;
  final bool bootstrapComplete;
  final int syncedAt;

  /// Horloge **serveur** (epoch ms) la plus récente parmi les classes
  /// itérées — `null` si aucune n'a rapporté de `serverTime` (tout
  /// `notModified`, ou aucune classe locale à itérer).
  final int? serverTimeMs;

  const CoursPullOutcome({
    required this.upserted,
    required this.notModified,
    required this.bootstrapComplete,
    required this.syncedAt,
    this.serverTimeMs,
  });

  @override
  List<Object?> get props => [
    upserted,
    notModified,
    bootstrapComplete,
    syncedAt,
    serverTimeMs,
  ];
}
