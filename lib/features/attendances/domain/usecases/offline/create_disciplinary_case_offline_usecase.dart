import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/offline_disciplinary_case.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/disciplinary_case_offline_repository.dart';

/// Création offline d'un cas disciplinaire (DF-1/2, régime A).
class CreateDisciplinaryCaseOfflineUseCase {
  final DisciplinaryCaseOfflineRepository _repository;

  const CreateDisciplinaryCaseOfflineUseCase(this._repository);

  Future<Either<Failure, OfflineDisciplinaryCase>> call({
    required String studentId,
    required String studentFirstName,
    required String studentLastName,
    String? studentMiddleName,
    required StudentGender studentGender,
    required DateTime disciplinaryCaseDate,
    required String academicYearId,
    required String title,
    required String content,
    required DisciplinaryCategory category,
    required DisciplinarySeverity severity,
    DisciplinarySanction? sanction,
  }) => _repository.createCase(
    studentId: studentId,
    studentFirstName: studentFirstName,
    studentLastName: studentLastName,
    studentMiddleName: studentMiddleName,
    studentGender: studentGender,
    disciplinaryCaseDate: disciplinaryCaseDate,
    academicYearId: academicYearId,
    title: title,
    content: content,
    category: category,
    severity: severity,
    sanction: sanction,
  );
}
