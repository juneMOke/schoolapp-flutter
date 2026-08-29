import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_catalog.dart';

/// Lecture du catalogue de la caisse — **100 % locale**.
///
/// Aucun appel réseau : le catalogue descend dans le bundle référentiel, et la
/// résolution du prix se fait entièrement hors ligne. C'est ce qui permet à la
/// caisse d'encaisser sans réseau, qui est le cas d'usage normal et non une
/// dégradation.
abstract class BoutiqueCatalogRepository {
  /// Le catalogue vendable de l'année, avec la raison de son vide s'il est vide.
  Future<Either<Failure, BoutiqueCatalog>> catalogOfYear(String academicYearId);
}
