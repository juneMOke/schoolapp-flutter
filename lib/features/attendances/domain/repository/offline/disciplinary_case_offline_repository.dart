import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/offline_disciplinary_case.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

/// Contrat offline-first des cas disciplinaires (DF-1/2).
///
/// Régime A (création : id uuid client, insert-only + outbox CREATE idempotent)
/// + régime C (traitement : update LWW status/sanction + outbox UPDATE).
abstract class DisciplinaryCaseOfflineRepository {
  /// Crée le FAIT localement (status OPEN, id client) + enfile un CREATE.
  Future<Either<Failure, OfflineDisciplinaryCase>> createCase({
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
  });

  /// Traite un cas (status + sanction COURANTE, LWW) + enfile un UPDATE.
  Future<Either<Failure, void>> updateCase({
    required String caseId,
    required DisciplinaryStatus status,
    DisciplinarySanction? sanction,
    int? expectedVersion,
  });

  /// Cas locaux d'un élève sur une année.
  Future<Either<Failure, List<OfflineDisciplinaryCase>>> getCasesForStudent({
    required String studentId,
    required String academicYearId,
  });

  /// Un cas local par id.
  Future<Either<Failure, OfflineDisciplinaryCase>> getCase({
    required String caseId,
  });
}
