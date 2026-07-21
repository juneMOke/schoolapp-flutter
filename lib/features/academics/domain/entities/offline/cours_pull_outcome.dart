import 'package:equatable/equatable.dart';

/// Bilan agrégé d'un pull des cours (itéré par classe — option B). [notModified]
/// vrai ⟺ **aucune** classe n'a rapporté de nouveauté ; [bootstrapComplete] vrai
/// ⟺ **toutes** les classes itérées ont bouclé leur premier passage complet.
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
