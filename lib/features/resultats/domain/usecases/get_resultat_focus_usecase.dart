import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_focus.dart';
import 'package:school_app_flutter/features/resultats/domain/repositories/resultats_repository.dart';

/// Charge la vue focus d'un élève.
///
/// Trois paramètres ⇒ objet [GetResultatFocusParams] dédié (convention projet).
class GetResultatFocusUseCase {
  final ResultatsRepository _repository;

  const GetResultatFocusUseCase(this._repository);

  Future<Either<Failure, ResultatFocus>> call(GetResultatFocusParams params) =>
      _repository.getResultatFocus(
        params.classroomId,
        params.periodeScolaireId,
        params.studentId,
      );
}

class GetResultatFocusParams extends Equatable {
  final String classroomId;
  final String periodeScolaireId;
  final String studentId;

  const GetResultatFocusParams({
    required this.classroomId,
    required this.periodeScolaireId,
    required this.studentId,
  });

  @override
  List<Object?> get props => [classroomId, periodeScolaireId, studentId];
}
