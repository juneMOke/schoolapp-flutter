import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultats_classe.dart';
import 'package:school_app_flutter/features/resultats/domain/repositories/resultats_repository.dart';

/// Charge la vue classe (synthèse + table roster × sous-période).
///
/// Trois paramètres ⇒ objet [GetResultatsClasseParams] dédié (convention projet).
class GetResultatsClasseUseCase {
  final ResultatsRepository _repository;

  const GetResultatsClasseUseCase(this._repository);

  Future<Either<Failure, ResultatsClasse>> call(
    GetResultatsClasseParams params,
  ) => _repository.getResultatsClasse(
    params.classroomId,
    params.periodeScolaireId,
    params.seuil,
  );
}

class GetResultatsClasseParams extends Equatable {
  final String classroomId;
  final String periodeScolaireId;

  /// `null` ⇒ le backend applique le seuil par défaut (50 %).
  final double? seuil;

  const GetResultatsClasseParams({
    required this.classroomId,
    required this.periodeScolaireId,
    this.seuil,
  });

  @override
  List<Object?> get props => [classroomId, periodeScolaireId, seuil];
}
