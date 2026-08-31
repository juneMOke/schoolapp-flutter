// Réponse canonique du commit agrégat (contrat `EnrollmentAggregateResponse`).
// 201 création / 200 rejeu idempotent. Un rejet de validation N'arrive PAS ici
// mais via un HTTP 422 (→ SYNC_ERROR côté handler).

/// Valeurs canoniques de l'inscription après commit serveur.
class ResponseEnrollment {
  final String id;
  final String? enrollmentCode; // numéro attribué serveur
  final String? status;

  /// Réductions réellement gravées (ADR-021 V1). **Le serveur fait foi** : il
  /// a pu en refuser une dont le code avait quitté le barème, et c'est cette
  /// liste-là qui doit rester en local — pas celle qu'on a envoyée.
  ///
  /// `null` = l'accusé ne porte pas la section (serveur antérieur au champ) :
  /// on garde ce que le guichet a déclaré, faute de mieux. `[]` = le serveur
  /// n'a rien gravé, et c'est une information.
  final List<String>? reductionCodes;

  const ResponseEnrollment({
    required this.id,
    this.enrollmentCode,
    this.status,
    this.reductionCodes,
  });

  factory ResponseEnrollment.fromJson(Map<String, dynamic> j) =>
      ResponseEnrollment(
        id: j['id'] as String,
        enrollmentCode: j['enrollmentCode'] as String?,
        status: j['status'] as String?,
        reductionCodes: j['reductionCodes'] == null
            ? null
            : [
                for (final code in (j['reductionCodes'] as List<dynamic>))
                  if (code is String) code,
              ],
      );
}

/// Valeurs canoniques de l'élève : le matricule généré serveur.
///
/// La réponse porte aussi un e-mail attribué ; il n'est plus décodé (ADR-015
/// F8). L'ACK le recopiait dans `students.email`, où personne n'allait jamais le
/// lire — contrairement au matricule, qui remonte jusqu'au ticket imprimé.
class ResponseStudent {
  final String id;
  final String? matriculationNumber;

  const ResponseStudent({required this.id, this.matriculationNumber});

  factory ResponseStudent.fromJson(Map<String, dynamic> j) => ResponseStudent(
    id: j['id'] as String,
    matriculationNumber: j['matriculationNumber'] as String?,
  );
}

/// Correspondance id provisoire → id canonique (get-or-create par téléphone).
class ParentRemap {
  final String providedId; // uuid provisoire envoyé
  final String canonicalId; // id canonique serveur
  final String? phoneNumber;
  final bool? created; // true = nouveau ; false = fratrie existante

  const ParentRemap({
    required this.providedId,
    required this.canonicalId,
    this.phoneNumber,
    this.created,
  });

  factory ParentRemap.fromJson(Map<String, dynamic> j) => ParentRemap(
    providedId: j['providedId'] as String,
    canonicalId: j['canonicalId'] as String,
    phoneNumber: j['phoneNumber'] as String?,
    created: j['created'] as bool?,
  );
}

/// Document scellé (attestation d'inscription — AI).
class GeneratedDocumentDto {
  final String type; // ENROLLMENT_CERTIFICATE
  final String documentNumber; // ETL-AI-…
  final String status; // DEFINITIVE
  final String? url;

  const GeneratedDocumentDto({
    required this.type,
    required this.documentNumber,
    required this.status,
    this.url,
  });

  factory GeneratedDocumentDto.fromJson(Map<String, dynamic> j) =>
      GeneratedDocumentDto(
        type: (j['type'] as String?) ?? 'ENROLLMENT_CERTIFICATE',
        documentNumber: (j['documentNumber'] as String?) ?? '',
        status: (j['status'] as String?) ?? 'DEFINITIVE',
        url: j['url'] as String?,
      );
}

/// Signal de doublon métier — informatif, jamais bloquant (D7/ADR-005).
class DeduplicationSignal {
  final bool? potentialDuplicate;
  final String? matchedStudentId;
  final String? reason;

  const DeduplicationSignal({
    this.potentialDuplicate,
    this.matchedStudentId,
    this.reason,
  });

  factory DeduplicationSignal.fromJson(Map<String, dynamic> j) =>
      DeduplicationSignal(
        potentialDuplicate: j['potentialDuplicate'] as bool?,
        matchedStudentId: j['matchedStudentId'] as String?,
        reason: j['reason'] as String?,
      );
}

/// Réponse du commit agrégat (201 création / 200 rejeu idempotent).
class EnrollmentAggregateResponse {
  final ResponseEnrollment enrollment;
  final ResponseStudent student;
  final List<ParentRemap> parents;
  final List<GeneratedDocumentDto> documents;
  final DeduplicationSignal? deduplication;

  const EnrollmentAggregateResponse({
    required this.enrollment,
    required this.student,
    this.parents = const [],
    this.documents = const [],
    this.deduplication,
  });

  factory EnrollmentAggregateResponse.fromJson(Map<String, dynamic> j) =>
      EnrollmentAggregateResponse(
        enrollment: ResponseEnrollment.fromJson(
          j['enrollment'] as Map<String, dynamic>,
        ),
        student: ResponseStudent.fromJson(j['student'] as Map<String, dynamic>),
        parents: (j['parents'] as List<dynamic>? ?? const [])
            .map((e) => ParentRemap.fromJson(e as Map<String, dynamic>))
            .toList(),
        documents: (j['documents'] as List<dynamic>? ?? const [])
            .map(
              (e) => GeneratedDocumentDto.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        deduplication: j['deduplication'] == null
            ? null
            : DeduplicationSignal.fromJson(
                j['deduplication'] as Map<String, dynamic>,
              ),
      );
}
