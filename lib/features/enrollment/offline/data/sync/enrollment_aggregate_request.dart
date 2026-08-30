import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_outbox_payload.dart';

/// Charge réseau du `POST /api/v1/sync/enrollments` (contrat
/// `EnrollmentAggregateRequest`), dérivée de la commande figée au moment du push.
/// Le contrat porte l'identité snapshottée + `studentId` sur l'`enrollment`, et
/// le tuteur par `id` provisoire (remappé dans la réponse).
class EnrollmentAggregateRequest {
  final EnrollmentCommand command;

  const EnrollmentAggregateRequest(this.command);

  Map<String, dynamic> toJson() {
    final s = command.student;
    final e = command.enrollment;
    return <String, dynamic>{
      // authorId au top-level (ADR-010 D-05) : recopié depuis la commande figée.
      if (command.authorId != null) 'authorId': command.authorId,
      'enrollment': <String, dynamic>{
        'id': e.id,
        'studentId': s.id,
        'schoolLevelId': e.schoolLevelId,
        'schoolLevelGroupId': e.schoolLevelGroupId,
        'academicYearId': e.academicYearId,
        'enrollmentType': e.enrollmentType,
        'status': e.status,
        'enrollmentDate': e.enrollmentDate,
        // identité snapshottée (exigée sur l'enrollment par le contrat)
        'firstName': s.firstName,
        'lastName': s.lastName,
        'surname': s.surname,
        'dateOfBirth': s.dateOfBirth,
        'gender': s.gender,
        'previousSchoolName': e.previousSchoolName,
        'previousAcademicYear': e.previousAcademicYear,
        'previousSchoolLevelGroup': e.previousSchoolLevelGroup,
        'previousSchoolLevel': e.previousSchoolLevel,
        'transferReason': e.transferReason,
        'previousRate': e.previousRate,
        'previousRank': e.previousRank,
        'validatedPreviousYear': e.validatedPreviousYear,
        'formerStudent': e.formerStudent,
        'medicalNotes': e.medicalNotes,
        // RE = matricule, PRE = id préinscription, NEW = null (posé au seed
        // du brouillon, transporté par le payload outbox).
        'sourceRef': e.sourceRef,
      },
      'student': <String, dynamic>{
        'id': s.id,
        'firstName': s.firstName,
        'lastName': s.lastName,
        'surname': s.surname,
        'gender': s.gender,
        'dateOfBirth': s.dateOfBirth,
        'birthPlace': s.birthPlace,
        'nationality': s.nationality,
        'city': s.city,
        'district': s.district,
        'municipality': s.municipality,
        'neighborhood': s.neighborhood,
        'address': s.address,
        'schoolLevelId': e.schoolLevelId,
        'schoolLevelGroupId': e.schoolLevelGroupId,
      },
      'parents': command.parents
          .map(
            (p) => <String, dynamic>{
              'id': p.clientId,
              'firstName': p.firstName,
              'lastName': p.lastName,
              'surname': p.surname ?? p.lastName,
              'phoneNumber': p.phoneNumber,
              'relationshipType': p.relationshipType,
              'email': p.email,
              // **Omis quand nul, jamais aplati en `false`.** Le serveur lit
              // l'absence comme « ne touche pas à la désignation en place » ;
              // un `false` écrit par confort retirerait un contact d'urgence
              // désigné depuis un autre poste, sans que personne l'ait demandé.
              if (p.emergencyContact != null)
                'emergencyContact': p.emergencyContact,
            },
          )
          .toList(),
    };
  }
}
