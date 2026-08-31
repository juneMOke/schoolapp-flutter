import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';

abstract class ParentRepository {
  Future<Either<Failure, ParentSummary>> updateParent({
    required String parentId,
    required String firstName,
    required String lastName,
    required String? surname,
    required String email,
    required String phoneNumber,
    required String relationshipType,
  });

  Future<Either<Failure, ParentSummary>> createParent({
    required String studentId,
    required String firstName,
    required String lastName,
    required String? surname,
    required String email,
    required String phoneNumber,
    required String relationshipType,
  });

  /// Désigne le tuteur à appeler en urgence pour [studentId], ou n'en désigne
  /// aucun ([parentId] à `null`).
  ///
  /// **100 % online, jamais mis en file d'attente.** Une désignation n'est pas
  /// une saisie de guichet qu'on rejoue plus tard : la route n'est pas
  /// idempotente au sens de l'outbox, et un rejeu différé désignerait
  /// peut-être un tuteur que quelqu'un a entre-temps délogé.
  Future<Either<Failure, Unit>> setEmergencyContact({
    required String studentId,
    required String? parentId,
  });

  Future<Either<Failure, void>> unlinkParent({
    required String studentId,
    required String parentId,
  });
}
