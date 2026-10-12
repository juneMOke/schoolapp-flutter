import 'package:equatable/equatable.dart';

/// Une classe de l'année, rattachée à son niveau.
class AudienceClassroom extends Equatable {
  final String id;
  final String name;
  final String? levelId;

  const AudienceClassroom({required this.id, required this.name, this.levelId});

  @override
  List<Object?> get props => [id, name, levelId];
}

/// Une tranche d'une nature de frais (`T1` du minerval), telle que la grille
/// la nomme.
class OverdueFeeTranche extends Equatable {
  final String code;
  final String label;

  const OverdueFeeTranche({required this.code, required this.label});

  @override
  List<Object?> get props => [code, label];
}

/// Une nature de frais facturée cette année (`TUITION`), et ses tranches
/// quand la grille en distingue plusieurs.
class OverdueFeeNature extends Equatable {
  final String feeCode;

  /// Le libellé de la grille quand la nature n'a qu'une ligne ; `null` sinon,
  /// aucun libellé ne valant alors pour l'ensemble.
  final String? singleLabel;
  final List<OverdueFeeTranche> tranches;

  const OverdueFeeNature({
    required this.feeCode,
    this.singleLabel,
    this.tranches = const [],
  });

  @override
  List<Object?> get props => [feeCode, singleLabel, tranches];
}

/// Ce que la tablette sait localement pour cibler : les classes et les frais
/// de l'année. Les niveaux viennent du contexte académique.
class AudienceReferential extends Equatable {
  final List<AudienceClassroom> classrooms;
  final List<OverdueFeeNature> fees;

  const AudienceReferential({this.classrooms = const [], this.fees = const []});

  List<AudienceClassroom> classroomsOf(String levelId) => [
    for (final classroom in classrooms)
      if (classroom.levelId == levelId) classroom,
  ];

  @override
  List<Object?> get props => [classrooms, fees];
}
