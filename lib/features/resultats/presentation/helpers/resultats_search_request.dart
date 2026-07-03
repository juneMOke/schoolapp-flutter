import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_search_mode.dart';

/// Requête émise par la carte de recherche à la validation (spec §1).
///
/// Réutilise les view-models de cascade de la feature `classes`
/// ([ClassesListCycleOption] / [ClassesListLevelOption] + [BootstrapClassroom]).
/// [classroom] est **toujours** renseigné (la validation l'exige) ; les noms
/// sont vides quand non saisis (ET côté backend, vide = absent).
class ResultatsSearchRequest extends Equatable {
  final ResultatsSearchMode mode;
  final ClassesListCycleOption cycle;
  final ClassesListLevelOption level;
  final BootstrapClassroom classroom;
  final String nom;
  final String postnom;
  final String prenom;

  const ResultatsSearchRequest({
    required this.mode,
    required this.cycle,
    required this.level,
    required this.classroom,
    required this.nom,
    required this.postnom,
    required this.prenom,
  });

  String get classroomLabel => classroom.name;

  @override
  List<Object?> get props => [
    mode,
    cycle,
    level,
    classroom,
    nom,
    postnom,
    prenom,
  ];
}
