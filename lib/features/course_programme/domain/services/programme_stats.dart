import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';

/// L'avancement d'un programme, **toujours dérivé** des chapitres, jamais
/// stocké ni descendu du serveur.
class ProgrammeStats extends Equatable {
  final int total;
  final int termines;
  final int enCours;
  final int planifies;

  /// Somme des séances prévues.
  final int seances;

  const ProgrammeStats({
    required this.total,
    required this.termines,
    required this.enCours,
    required this.planifies,
    required this.seances,
  });

  static const ProgrammeStats empty = ProgrammeStats(
    total: 0,
    termines: 0,
    enCours: 0,
    planifies: 0,
    seances: 0,
  );

  factory ProgrammeStats.of(Iterable<Chapitre> chapitres) {
    var termines = 0, enCours = 0, planifies = 0, seances = 0, total = 0;
    for (final chapitre in chapitres) {
      total++;
      seances += chapitre.seances;
      switch (chapitre.statut) {
        case ChapitreStatut.termine:
          termines++;
        case ChapitreStatut.enCours:
          enCours++;
        case ChapitreStatut.planifie:
          planifies++;
      }
    }
    return ProgrammeStats(
      total: total,
      termines: termines,
      enCours: enCours,
      planifies: planifies,
      seances: seances,
    );
  }

  /// Part des chapitres terminés, arrondie ; 0 pour un programme vide.
  int get percent => total == 0 ? 0 : (termines * 100 / total).round();

  @override
  List<Object?> get props => [total, termines, enCours, planifies, seances];
}
