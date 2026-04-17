import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/bootstrap/data/datasources/bootstrap_local_data_source.dart';
import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_academic_year_model.dart';
import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_classroom_model.dart';
import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_model.dart';
import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_school_level_bundle_model.dart';
import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_school_level_group_bundle_model.dart';
import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_school_level_group_model.dart';
import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_school_level_model.dart';
import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_tariff_model.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/bootstrap/domain/repositories/bootstrap_local_repository.dart';

class BootstrapLocalRepositoryImpl implements BootstrapLocalRepository {
  final BootstrapLocalDataSource localDataSource;

  const BootstrapLocalRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Bootstrap>> getStoredBootstrap(String key) async {
    try {
      final model = await localDataSource.readBootstrap(key);
      if (model == null) {
        return const Left(StorageFailure('No stored bootstrap found'));
      }
      return Right(model.toEntity());
    } catch (_) {
      return const Left(StorageFailure('Failed to read bootstrap'));
    }
  }

  @override
  Future<Either<Failure, void>> saveBootstrap({
    required Bootstrap bootstrap,
    required String key,
  }) async {
    try {
      await localDataSource.saveBootstrap(_toModel(bootstrap), key);
      return const Right(null);
    } catch (_) {
      return const Left(StorageFailure('Failed to save bootstrap'));
    }
  }

  @override
  Future<Either<Failure, void>> clearBootstrap(String key) async {
    try {
      await localDataSource.clearBootstrap(key);
      return const Right(null);
    } catch (_) {
      return const Left(StorageFailure('Failed to clear bootstrap'));
    }
  }

  BootstrapModel _toModel(Bootstrap bootstrap) {
    return BootstrapModel(
      schoolId: bootstrap.schoolId,
      academicYear: BootstrapAcademicYearModel(
        id: bootstrap.academicYear.id,
        name: bootstrap.academicYear.name,
        startDate: bootstrap.academicYear.startDate,
        endDate: bootstrap.academicYear.endDate,
        current: bootstrap.academicYear.current,
      ),
      schoolLevelGroups: bootstrap.schoolLevelGroups
          .map(
            (groupBundle) => BootstrapSchoolLevelGroupBundleModel(
              schoolLevelGroup: BootstrapSchoolLevelGroupModel(
                id: groupBundle.schoolLevelGroup.id,
                version: groupBundle.schoolLevelGroup.version,
                name: groupBundle.schoolLevelGroup.name,
                code: groupBundle.schoolLevelGroup.code,
                periodType: groupBundle.schoolLevelGroup.periodType,
                displayOrder: groupBundle.schoolLevelGroup.displayOrder,
              ),
              schoolLevels: groupBundle.schoolLevels
                  .map(
                    (levelBundle) => BootstrapSchoolLevelBundleModel(
                      schoolLevel: BootstrapSchoolLevelModel(
                        id: levelBundle.schoolLevel.id,
                        version: levelBundle.schoolLevel.version,
                        name: levelBundle.schoolLevel.name,
                        code: levelBundle.schoolLevel.code,
                        displayOrder: levelBundle.schoolLevel.displayOrder,
                      ),
                      classrooms: levelBundle.classrooms
                          .map(
                            (classroom) => BootstrapClassroomModel(
                              id: classroom.id,
                              version: classroom.version,
                              schoolLevelId: classroom.schoolLevelId,
                              name: classroom.name,
                              capacity: classroom.capacity,
                              totalCount: classroom.totalCount,
                              femaleCount: classroom.femaleCount,
                              maleCount: classroom.maleCount,
                            ),
                          )
                          .toList(),
                      tariffs: levelBundle.tariffs
                          .map(
                            (tariff) => BootstrapTariffModel(
                              id: tariff.id,
                              version: tariff.version,
                              feeCode: tariff.feeCode,
                              label: tariff.label,
                              schoolLevelGroupId: tariff.schoolLevelGroupId,
                              schoolLevelId: tariff.schoolLevelId,
                              academicYearId: tariff.academicYearId,
                              amountInCents: tariff.amountInCents,
                              currency: tariff.currency,
                              dueAt: tariff.dueAt,
                            ),
                          )
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }
}
