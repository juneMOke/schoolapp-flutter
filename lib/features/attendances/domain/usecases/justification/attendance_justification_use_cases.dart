import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/attendance_justification.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/justification_enums.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/justification/attendance_justification_repository.dart';

// Les cas d'usage des justifications d'absence des parents (portail parent).

class LoadAttendanceJustificationsUseCase {
  final AttendanceJustificationRepository _repository;

  const LoadAttendanceJustificationsUseCase(this._repository);

  Future<Either<Failure, List<AttendanceJustification>>> call(
    String academicYearId,
  ) => _repository.list(academicYearId);
}

class DecideAttendanceJustificationUseCase {
  final AttendanceJustificationRepository _repository;

  const DecideAttendanceJustificationUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    AttendanceJustification justification,
    JustificationDecision decision, {
    String? note,
  }) => _repository.decide(justification, decision, note: note);
}

class OpenJustificationAttachmentUseCase {
  final AttendanceJustificationRepository _repository;

  const OpenJustificationAttachmentUseCase(this._repository);

  Future<Either<Failure, Uint8List>> call(
    AttendanceJustification justification,
  ) => _repository.attachment(justification);
}

class AcknowledgeJustificationNoticeUseCase {
  final AttendanceJustificationRepository _repository;

  const AcknowledgeJustificationNoticeUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String id) =>
      _repository.acknowledgeDecidedElsewhere(id);
}
