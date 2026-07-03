// `dartz` exporte aussi un type `Evaluation` : on le masque au profit de notre
// entité domaine.
import 'package:dartz/dartz.dart' hide Evaluation;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation.dart';

abstract class CourseRepository {
  /// Récupère les cours de l'enseignant connecté, regroupés par classe.
  ///
  /// L'enseignant est résolu côté backend depuis le sujet du JWT : aucun
  /// paramètre n'est nécessaire ici.
  Future<Either<Failure, List<CourseSummary>>> getMyCourses();

  /// Récupère le détail de notation d'un cours par période puis sous-période.
  Future<Either<Failure, CoursNotationDetail>> getCoursNotationDetail(
    String coursId,
  );

  /// Crée une évaluation sous [coursId] et renvoie l'évaluation créée.
  ///
  /// [request] garantit l'exclusivité temporelle par construction (cf. ses
  /// factories `examen` / `journaliere`).
  Future<Either<Failure, Evaluation>> createEvaluation(
    String coursId,
    CreateEvaluationRequest request,
  );
}
