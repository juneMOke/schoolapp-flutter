import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/attendance_justification.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/justification_enums.dart';

/// Les justifications d'absence des parents, côté école.
///
/// Lecture 100 % locale (le miroir du flux `attendance.justifications`) ;
/// décision 100 % outbox ; la pièce jointe, elle, ne se lit qu'en ligne ou
/// depuis le dossier temporaire de la session.
abstract class AttendanceJustificationRepository {
  /// Toutes les justifications de l'année, les plus récentes d'abord.
  Future<Either<Failure, List<AttendanceJustification>>> list(
    String academicYearId,
  );

  /// Tranche une demande. Le refus porte le mot de l'école au parent.
  Future<Either<Failure, Unit>> decide(
    AttendanceJustification justification,
    JustificationDecision decision, {
    String? note,
  });

  /// Les octets de la pièce jointe. `NetworkFailure` hors connexion quand la
  /// pièce n'est pas déjà dans le dossier temporaire.
  Future<Either<Failure, Uint8List>> attachment(
    AttendanceJustification justification,
  );

  /// L'avis « tranchée par un autre poste » a été montré : il ne revient pas.
  Future<Either<Failure, Unit>> acknowledgeDecidedElsewhere(String id);
}
