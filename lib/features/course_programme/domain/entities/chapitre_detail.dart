import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';

/// Une évaluation qui porte sur un chapitre (rattachement par `chapitreId`).
class ChapitreEvaluationLink extends Equatable {
  final String id;
  final TypeEvaluation type;
  final DateTime date;
  final double maxPoints;

  const ChapitreEvaluationLink({
    required this.id,
    required this.type,
    required this.date,
    required this.maxPoints,
  });

  @override
  List<Object?> get props => [id, type, date, maxPoints];
}

/// Le détail d'un chapitre : la fiche, ses notes et ressources chargées, et
/// les évaluations qui le citent (la plus récente en tête).
class ChapitreDetail extends Equatable {
  final Chapitre chapitre;
  final List<ChapitreEvaluationLink> evaluations;

  /// Rang d'affichage, à partir de 1 (le numéro de la rangée).
  final int numero;

  const ChapitreDetail({
    required this.chapitre,
    required this.numero,
    this.evaluations = const [],
  });

  @override
  List<Object?> get props => [chapitre, evaluations, numero];
}
