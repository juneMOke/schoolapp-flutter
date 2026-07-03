import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/bulletin_domaine.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/focus_entete.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/matiere_score.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/progression_point.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/synthese.dart';

/// Vue focus d'un élève : en-tête (moyenne annuelle + rang), progression P1..Pn,
/// top3/bottom3 matières, bulletin par domaine et synthèse. Calcul live.
///
/// [bulletinParDomaine] `null` (élève non classé sur le groupe) est un cas
/// **valide** (rendu « — »), pas une erreur. [progression] (par `indexGlobal`),
/// [topMatieres] et [bottomMatieres] (≤ 3) arrivent déjà ordonnés.
class ResultatFocus extends Equatable {
  final String classroomId;
  final String periodeScolaireId;
  final int periodeOrdre;
  final FocusEntete entete;
  final List<ProgressionPoint> progression;

  /// Dernier point noté − premier (pts) ; `null` si indéterminable.
  final double? deltaPts;
  final List<MatiereScore> topMatieres;
  final List<MatiereScore> bottomMatieres;
  final BulletinDomaine? bulletinParDomaine;
  final Synthese synthese;

  const ResultatFocus({
    required this.classroomId,
    required this.periodeScolaireId,
    required this.periodeOrdre,
    required this.entete,
    required this.progression,
    this.deltaPts,
    required this.topMatieres,
    required this.bottomMatieres,
    this.bulletinParDomaine,
    required this.synthese,
  });

  @override
  List<Object?> get props => [
    classroomId,
    periodeScolaireId,
    periodeOrdre,
    entete,
    progression,
    deltaPts,
    topMatieres,
    bottomMatieres,
    bulletinParDomaine,
    synthese,
  ];
}
