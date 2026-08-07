import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';
import 'package:school_app_flutter/features/school/domain/entities/school.dart';
import 'package:school_app_flutter/features/school/domain/repositories/school_repository.dart';

/// Lit `ref_school` via le DAO référentiel d'Inscription — même source que le
/// contexte académique, qui s'appuie déjà sur ce DAO pour les années et les
/// cycles. Aucune table ni aucun pull propres à cette feature.
class SchoolRepositoryImpl implements SchoolRepository {
  final EnrollmentReferentialDao _referentialDao;
  final CurrentUserContext _currentUser;

  const SchoolRepositoryImpl({
    required EnrollmentReferentialDao referentialDao,
    required CurrentUserContext currentUser,
  }) : _referentialDao = referentialDao,
       _currentUser = currentUser;

  @override
  Future<Either<Failure, School?>> loadCurrentSchool() async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null) return const Right(null);

    try {
      final row = await _referentialDao.getSchool();
      if (row == null) return const Right(null);

      // `ref_school` est mono-ligne et réécrite en entier à chaque pull : sur
      // un device multi-école, elle peut porter une AUTRE école que celle de
      // la session en cours. Afficher ce nom-là serait pire que n'en afficher
      // aucun — on préfère taire l'identité.
      if (row.id != schoolId) return const Right(null);

      return Right(
        School(
          id: row.id,
          name: row.name,
          country: row.country,
          city: row.city,
          district: row.district,
          municipality: row.municipality,
          address: row.address,
          phone: row.phone,
          email: row.email,
        ),
      );
    } catch (error) {
      return Left(StorageFailure('Identité de l\'école illisible : $error'));
    }
  }
}
