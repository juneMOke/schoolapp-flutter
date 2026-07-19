import 'package:equatable/equatable.dart';

/// Bilan agrégé d'un pull des cours (itéré par classe — option B). [notModified]
/// vrai ⟺ **aucune** classe n'a rapporté de nouveauté ; [bootstrapComplete] vrai
/// ⟺ **toutes** les classes itérées ont bouclé leur premier passage complet.
class CoursPullOutcome extends Equatable {
  final int upserted;
  final bool notModified;
  final bool bootstrapComplete;
  final int syncedAt;

  const CoursPullOutcome({
    required this.upserted,
    required this.notModified,
    required this.bootstrapComplete,
    required this.syncedAt,
  });

  @override
  List<Object?> get props => [
    upserted,
    notModified,
    bootstrapComplete,
    syncedAt,
  ];
}
