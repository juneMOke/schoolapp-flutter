import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_catalog.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_catalog_repository.dart';

/// Le catalogue vendable de l'année courante, pour l'écran de caisse.
class GetBoutiqueCatalogUseCase {
  final BoutiqueCatalogRepository _repository;

  const GetBoutiqueCatalogUseCase(this._repository);

  Future<Either<Failure, BoutiqueCatalog>> call(String academicYearId) =>
      _repository.catalogOfYear(academicYearId);
}
