import 'package:equatable/equatable.dart';

/// Bilan agrégé d'un pull delta métier (évaluations ou notes), itéré par cours.
/// [notModified] vrai ⟺ aucun cours n'a rapporté de nouveauté ;
/// [bootstrapComplete] vrai ⟺ tous les cours itérés ont bouclé leur premier
/// passage complet.
class AcademicsDeltaPullOutcome extends Equatable {
  final int upserted;
  final bool notModified;
  final bool bootstrapComplete;
  final int syncedAt;

  const AcademicsDeltaPullOutcome({
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
