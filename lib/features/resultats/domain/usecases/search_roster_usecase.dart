import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/resultats/domain/repositories/resultats_repository.dart';

/// Recherche roster scopée classe (mode « Par élève ») ; réutilise l'entité
/// partagée [ClassroomMember].
///
/// Paramètres multiples ⇒ objet [SearchRosterParams] dédié (convention projet).
class SearchRosterUseCase {
  final ResultatsRepository _repository;

  const SearchRosterUseCase(this._repository);

  Future<Either<Failure, List<ClassroomMember>>> call(
    SearchRosterParams params,
  ) => _repository.searchRoster(
    params.classroomId,
    params.academicYearId,
    params.nom,
    params.postnom,
    params.prenom,
  );
}

class SearchRosterParams extends Equatable {
  final String classroomId;
  final String academicYearId;
  final String? nom;
  final String? postnom;
  final String? prenom;

  const SearchRosterParams({
    required this.classroomId,
    required this.academicYearId,
    this.nom,
    this.postnom,
    this.prenom,
  });

  @override
  List<Object?> get props => [
    classroomId,
    academicYearId,
    nom,
    postnom,
    prenom,
  ];
}
