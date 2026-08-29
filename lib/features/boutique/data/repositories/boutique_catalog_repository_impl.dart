import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/auth/permission_policy.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_catalog_dao.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_catalog.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_catalog_repository.dart';

/// Lecture locale du catalogue, et **traduction des modèles en entités ici** —
/// jamais dans un BLoC.
class BoutiqueCatalogRepositoryImpl implements BoutiqueCatalogRepository {
  final BoutiqueCatalogDao _dao;
  final CurrentUserContext _currentUser;

  /// Les permissions effectives du porteur de session, résolues à l'appel.
  ///
  /// Injectées plutôt que lues d'un singleton global pour que le test puisse
  /// exercer les deux vides sans monter une session.
  final List<String>? Function() _permissions;

  const BoutiqueCatalogRepositoryImpl({
    required BoutiqueCatalogDao dao,
    required CurrentUserContext currentUser,
    required List<String>? Function() permissions,
  }) : _dao = dao,
       _currentUser = currentUser,
       _permissions = permissions;

  @override
  Future<Either<Failure, BoutiqueCatalog>> catalogOfYear(
    String academicYearId,
  ) async {
    // Le catalogue vide et le catalogue retenu se distinguent par la
    // PERMISSION, pas par un état mémorisé : le serveur caviarde la section
    // exactement sur `boutique.catalog.read`, et le client connaît ses droits.
    // Mémoriser en base « on ne me l'a pas servi » ajouterait une donnée qui
    // pourrit — un droit accordé entre-temps la laisserait mentir jusqu'au pull
    // suivant.
    final permissions = _permissions();
    final withheld = !canAccess(
      requires: const [Perm.boutiqueCatalogRead],
      permissions: permissions,
    );
    if (withheld) return const Right(BoutiqueCatalog.withheld());

    try {
      final rows = await _dao.articlesOfYear(
        schoolId: _currentUser.schoolId ?? '',
        academicYearId: academicYearId,
      );
      return Right(
        BoutiqueCatalog(
          articles: [for (final row in rows) row.toEntity()],
          withheld: false,
        ),
      );
    } catch (e) {
      // Une lecture d'affichage ne remonte pas d'exception nue : l'écran a un
      // état d'erreur, et une base illisible n'est pas un catalogue vide.
      return Left(StorageFailure('Catalogue boutique illisible : $e'));
    }
  }
}
