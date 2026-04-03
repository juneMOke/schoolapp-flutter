import 'package:school_app_flutter/features/academic_year/data/models/academic_year_model.dart';
import 'package:school_app_flutter/features/academic_year/data/services/academic_year_storage_service.dart';

abstract class AcademicYearLocalDataSource {
  Future<AcademicYearModel?> readAcademicYear();
  Future<void> saveAcademicYear(AcademicYearModel academicYear);
  Future<void> clearAcademicYear();
}

class AcademicYearLocalDataSourceImpl implements AcademicYearLocalDataSource {
  final AcademicYearStorageService _storageService;

  const AcademicYearLocalDataSourceImpl(this._storageService);

  @override
  Future<AcademicYearModel?> readAcademicYear() async {
    return await _storageService.readAcademicYear();
  }

  @override
  Future<void> saveAcademicYear(AcademicYearModel academicYear) async {
    await _storageService.saveAcademicYear(academicYear);
  }

  @override
  Future<void> clearAcademicYear() async {
    await _storageService.clearAcademicYear();
  }
}
