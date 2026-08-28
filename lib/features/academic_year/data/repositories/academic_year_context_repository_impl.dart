import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/domain/repositories/academic_year_context_repository.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_pull_repository.dart';

class AcademicYearContextRepositoryImpl
    implements AcademicYearContextRepository {
  final EnrollmentReferentialDao _referentialDao;
  final EnrollmentPullRepository _pullRepository;
  final ConnectivityService _connectivity;
  final CurrentUserContext _currentUser;

  const AcademicYearContextRepositoryImpl({
    required EnrollmentReferentialDao referentialDao,
    required EnrollmentPullRepository pullRepository,
    required ConnectivityService connectivity,
    required CurrentUserContext currentUser,
  }) : _referentialDao = referentialDao,
       _pullRepository = pullRepository,
       _connectivity = connectivity,
       _currentUser = currentUser;

  @override
  Future<Either<Failure, AcademicYearContext>> loadCurrentContext() async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null) {
      return const Left(AuthFailure('Aucune session active'));
    }

    var yearId = await _referentialDao.findCurrentAcademicYearId(schoolId);
    if (yearId == null) {
      if (!await _connectivity.isOnline()) {
        return const Left(
          NetworkFailure('Référentiel indisponible hors connexion'),
        );
      }
      final pullFailure = (await _pullRepository.syncReferential()).fold(
        (failure) => failure,
        (_) => null,
      );
      if (pullFailure != null) return Left(pullFailure);
      yearId = await _referentialDao.findCurrentAcademicYearId(schoolId);
      if (yearId == null) {
        // Le pull a réussi et le serveur ne connaît aucune année pour cette
        // école : ce n'est pas une panne, c'est un établissement qui n'a pas
        // encore été paramétré. La distinction porte l'écran — une panne se
        // réessaie, un paramétrage manquant se fait.
        return const Left(
          SchoolNotProvisionedFailure(
            'Aucune année scolaire courante pour cette école',
          ),
        );
      }
    }

    final context = await _buildContext(yearId);
    if (context == null) {
      return const Left(
        ServerFailure('Année scolaire courante introuvable en local'),
      );
    }
    return Right(context);
  }

  @override
  Future<Either<Failure, AcademicYearContext?>> loadPreviousContext() async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null) {
      return const Left(AuthFailure('Aucune session active'));
    }

    final yearId = await _referentialDao.findPreviousAcademicYearId(schoolId);
    if (yearId == null) return const Right(null);

    final context = await _buildContext(yearId);
    return Right(context);
  }

  @override
  Future<void> markSchoolLevelSplit(String schoolLevelId) =>
      _referentialDao.markSchoolLevelSplit(schoolLevelId);

  Future<AcademicYearContext?> _buildContext(String academicYearId) async {
    final yearRow = await _referentialDao.getAcademicYearById(academicYearId);
    if (yearRow == null) return null;

    final groupRows = await _referentialDao.getSchoolLevelGroups(
      academicYearId,
    );
    final levelRows = await _referentialDao.getSchoolLevelsByGroupIds([
      for (final g in groupRows) g.id,
    ]);

    final bundles = [
      for (final g in groupRows)
        SchoolLevelGroupBundle(
          group: SchoolLevelGroup(
            id: g.id,
            name: g.name,
            code: g.code,
            displayOrder: g.displayOrder,
            periodType: g.periodType,
          ),
          levels: [
            for (final l in levelRows)
              if (l.levelGroupId == g.id)
                SchoolLevel(
                  id: l.id,
                  name: l.name,
                  code: l.code,
                  displayOrder: l.displayOrder,
                  splitIntoClassrooms: l.splitIntoClassrooms,
                ),
          ],
        ),
    ];

    return AcademicYearContext(
      academicYear: AcademicYear(
        id: yearRow.id,
        name: yearRow.name,
        startDate: yearRow.startDate == null
            ? null
            : DateTime.tryParse(yearRow.startDate!),
        endDate: yearRow.endDate == null
            ? null
            : DateTime.tryParse(yearRow.endDate!),
        current: yearRow.isCurrent,
      ),
      schoolLevelGroups: bundles,
    );
  }
}
