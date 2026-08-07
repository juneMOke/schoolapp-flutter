import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Popin "Rechercher un parent" (étape Tuteurs) : recherche locale d'un
/// tuteur déjà connu par nom/postnom/prénom et/ou téléphone.
class SearchParentsUseCase {
  final EnrollmentOfflineRepository _repository;

  const SearchParentsUseCase(this._repository);

  Future<Either<Failure, List<LocalParent>>> call({
    String? firstName,
    String? lastName,
    String? surname,
    String? phoneNumber,
    int limit = 20,
  }) => _repository.searchParents(
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    phoneNumber: phoneNumber,
    limit: limit,
  );
}
