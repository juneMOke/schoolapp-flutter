// Réponse canonique du commit agrégat (contrat `EnrollmentAggregateResponse`).
// 201 création / 200 rejeu idempotent. Un rejet de validation N'arrive PAS ici
// mais via un HTTP 422 (→ SYNC_ERROR côté handler).

import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_models.dart'
    show StudentChargeDto;

/// Valeurs canoniques de l'inscription après commit serveur.
class ResponseEnrollment {
  final String id;
  final String? enrollmentCode; // numéro attribué serveur
  final String? status;

  const ResponseEnrollment({
    required this.id,
    this.enrollmentCode,
    this.status,
  });

  factory ResponseEnrollment.fromJson(Map<String, dynamic> j) =>
      ResponseEnrollment(
        id: j['id'] as String,
        enrollmentCode: j['enrollmentCode'] as String?,
        status: j['status'] as String?,
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

  /// Réductions réellement gravées (ADR-021 V1). **À la racine de l'accusé**,
  /// à côté de [enrollment] et non dedans — l'octroi n'est pas une colonne de
  /// l'inscription, c'est une table à lui.
  ///
  /// **Le serveur fait foi** : il refuse en 422 un code sorti du barème, donc
  /// ce qui revient ici est ce qui est gravé — y compris sur un rejeu, où ce
  /// sont les octrois déjà en place et non un second octroi.
  ///
  /// `null` = l'accusé ne porte pas la section : on garde ce que le guichet a
  /// déclaré, faute de mieux. `[]` = le serveur n'a rien gravé, et c'est une
  /// information.
  final List<String>? reductionCodes;
  final List<GeneratedDocumentDto> documents;

  /// Créances **autoritaires** matérialisées par le serveur DANS la transaction
  /// d'inscription (contrat `StudentChargeRef`).
  ///
  /// Le poste a généré les siennes en `PROVISIONAL` depuis sa grille gelée —
  /// sans elles il ne pourrait rien encaisser pour l'élève qu'il vient
  /// d'inscrire, or c'est le cas nominal de la rentrée. Elles ne sont jamais
  /// poussées : elles attendent d'être REMPLACÉES, et c'est ici que ça se joue.
  ///
  /// Les ignorer laissait le guichet encaisser, entre l'accusé et le pull
  /// suivant, sur des créances provisoires — dont le serveur ne connaît ni les
  /// ids ni, avant que le semis ne les matérialise toutes, l'existence même.
  ///
  /// Vide est un cas NORMAL : pré-inscription, ou inscription sans niveau. Le
  /// serveur n'a alors rien à matérialiser.
  final List<StudentChargeDto> charges;
  final DeduplicationSignal? deduplication;

  const EnrollmentAggregateResponse({
    required this.enrollment,
    required this.student,
    this.parents = const [],
    this.reductionCodes,
    this.documents = const [],
    this.charges = const [],
    this.deduplication,
  });

  factory EnrollmentAggregateResponse.fromJson(Map<String, dynamic> j) =>
      EnrollmentAggregateResponse(
        enrollment: ResponseEnrollment.fromJson(
          j['enrollment'] as Map<String, dynamic>,
        ),
        reductionCodes: j['reductionCodes'] == null
            ? null
            : [
                for (final code in (j['reductionCodes'] as List<dynamic>))
                  if (code is String) code,
              ],
        student: ResponseStudent.fromJson(j['student'] as Map<String, dynamic>),
        parents: (j['parents'] as List<dynamic>? ?? const [])
            .map((e) => ParentRemap.fromJson(e as Map<String, dynamic>))
            .toList(),
        documents: (j['documents'] as List<dynamic>? ?? const [])
            .map(
              (e) => GeneratedDocumentDto.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        // Même forme JSON que le delta du pull, donc même lecture : la
        // normalisation (UNPAID → DUE, soldes autoritaires) ne doit pas exister
        // en deux exemplaires.
        charges: (j['charges'] as List<dynamic>? ?? const [])
            .map((e) => StudentChargeDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        deduplication: j['deduplication'] == null
            ? null
            : DeduplicationSignal.fromJson(
                j['deduplication'] as Map<String, dynamic>,
              ),
      );
}
