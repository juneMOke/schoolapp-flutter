import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_detail.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_summary.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

abstract class DisciplinaryCaseRepository {
  Future<Either<Failure, List<DisciplinaryCaseSummary>>>
  getDisciplinaryCaseList({
    required String studentId,
    required String academicYearId,
  });

  Future<Either<Failure, DisciplinaryCaseDetail>> getDisciplinaryCaseDetail({
    required String caseId,
  });

  Future<Either<Failure, DisciplinaryCaseSummary>> createDisciplinaryCase({
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
    required DisciplinarySanction sanction,
  });

  /// Traitement d'un cas (DF-2, régime C) : `PUT /disciplinary-cases/{caseId}`.
  /// Renvoie TOUJOURS la sanction courante (sinon effacement — DG-3). `409` →
  /// [ConflictFailure] (verrou optimiste périmé, refetch + rejeu LWW en amont).
  Future<Either<Failure, void>> updateDisciplinaryCaseStatus({
    required String caseId,
    required DisciplinaryStatus status,
    DisciplinarySanction? sanction,
    int? expectedVersion,
  });
}
