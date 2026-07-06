// Contrat Dart de l'endpoint agrégat `POST /api/v1/sync/enrollments`
// (F-Lot 4). Miroir strict de `SPEC_Backend_Enrollment_Offline_V1` : clés
// camelCase, dates `yyyy-MM-dd`. Requête = toJson ; réponse (ACK) = fromJson.

// ── Requête ──────────────────────────────────────────────────────────────────

/// Payload élève. PAS de matricule/email : générés serveur.
class StudentPayload {
  final String id; // uuid client (NEW) | id serveur (RE/PRE)
  final String firstName;
  final String lastName;
  final String surname;
  final String gender; // MALE|FEMALE|OTHER
  final String dateOfBirth; // yyyy-MM-dd
  final String birthPlace;
  final String nationality;
  final String? city;
  final String? district;
  final String? municipality;
  final String? neighborhood;
  final String? address;

  const StudentPayload({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.gender,
    required this.dateOfBirth,
    required this.birthPlace,
    required this.nationality,
    this.city,
    this.district,
    this.municipality,
    this.neighborhood,
    this.address,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'surname': surname,
    'gender': gender,
    'dateOfBirth': dateOfBirth,
    'birthPlace': birthPlace,
    'nationality': nationality,
    'city': city,
    'district': district,
    'municipality': municipality,
    'neighborhood': neighborhood,
    'address': address,
  };

  factory StudentPayload.fromJson(Map<String, dynamic> j) => StudentPayload(
    id: j['id'] as String,
    firstName: j['firstName'] as String,
    lastName: j['lastName'] as String,
    surname: (j['surname'] as String?) ?? '',
    gender: j['gender'] as String,
    dateOfBirth: j['dateOfBirth'] as String,
    birthPlace: (j['birthPlace'] as String?) ?? '',
    nationality: (j['nationality'] as String?) ?? '',
    city: j['city'] as String?,
    district: j['district'] as String?,
    municipality: j['municipality'] as String?,
    neighborhood: j['neighborhood'] as String?,
    address: j['address'] as String?,
  );
}

/// Payload tuteur (get-or-create par téléphone côté serveur).
class ParentPayload {
  final String clientId; // uuid provisoire local (corrélation du remap)
  final String firstName;
  final String lastName;
  final String? surname; // serveur résout à lastName si absent
  final String phoneNumber; // clé naturelle
  final String? email;
  final String relationshipType; // FATHER|MOTHER|GUARDIAN|GRANDPARENT|OTHER

  const ParentPayload({
    required this.clientId,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.phoneNumber,
    this.email,
    required this.relationshipType,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'clientId': clientId,
    'firstName': firstName,
    'lastName': lastName,
    'surname': surname,
    'phoneNumber': phoneNumber,
    'email': email,
    'relationshipType': relationshipType,
  };

  factory ParentPayload.fromJson(Map<String, dynamic> j) => ParentPayload(
    clientId: j['clientId'] as String,
    firstName: j['firstName'] as String,
    lastName: j['lastName'] as String,
    surname: j['surname'] as String?,
    phoneNumber: j['phoneNumber'] as String,
    email: j['email'] as String?,
    relationshipType: (j['relationshipType'] as String?) ?? 'OTHER',
  );
}

/// Payload inscription. `id` = uuid client (clé d'idempotence).
class EnrollmentPayload {
  final String id;
  final String enrollmentType;
  final String status;
  final String academicYearId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String enrollmentDate; // yyyy-MM-dd — honoré serveur
  final String? previousSchoolName;
  final String? previousAcademicYear;
  final String? previousSchoolLevelGroup;
  final String? previousSchoolLevel;
  final double? previousRate;
  final int? previousRank;
  final bool? validatedPreviousYear;
  final String? transferReason;
  final String? cancellationReason;

  const EnrollmentPayload({
    required this.id,
    required this.enrollmentType,
    required this.status,
    required this.academicYearId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    required this.enrollmentDate,
    this.previousSchoolName,
    this.previousAcademicYear,
    this.previousSchoolLevelGroup,
    this.previousSchoolLevel,
    this.previousRate,
    this.previousRank,
    this.validatedPreviousYear,
    this.transferReason,
    this.cancellationReason,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'enrollmentType': enrollmentType,
    'status': status,
    'academicYearId': academicYearId,
    'schoolLevelId': schoolLevelId,
    'schoolLevelGroupId': schoolLevelGroupId,
    'enrollmentDate': enrollmentDate,
    'previousSchoolName': previousSchoolName,
    'previousAcademicYear': previousAcademicYear,
    'previousSchoolLevelGroup': previousSchoolLevelGroup,
    'previousSchoolLevel': previousSchoolLevel,
    'previousRate': previousRate,
    'previousRank': previousRank,
    'validatedPreviousYear': validatedPreviousYear,
    'transferReason': transferReason,
    'cancellationReason': cancellationReason,
  };

  factory EnrollmentPayload.fromJson(Map<String, dynamic> j) =>
      EnrollmentPayload(
        id: j['id'] as String,
        enrollmentType: j['enrollmentType'] as String,
        status: j['status'] as String,
        academicYearId: j['academicYearId'] as String,
        schoolLevelId: j['schoolLevelId'] as String?,
        schoolLevelGroupId: j['schoolLevelGroupId'] as String?,
        enrollmentDate: j['enrollmentDate'] as String,
        previousSchoolName: j['previousSchoolName'] as String?,
        previousAcademicYear: j['previousAcademicYear'] as String?,
        previousSchoolLevelGroup: j['previousSchoolLevelGroup'] as String?,
        previousSchoolLevel: j['previousSchoolLevel'] as String?,
        previousRate: (j['previousRate'] as num?)?.toDouble(),
        previousRank: j['previousRank'] as int?,
        validatedPreviousYear: j['validatedPreviousYear'] as bool?,
        transferReason: j['transferReason'] as String?,
        cancellationReason: j['cancellationReason'] as String?,
      );
}

/// Une commande = un agrégat inscription (parent[s] + student + link + enroll).
class EnrollmentCommand {
  final EnrollmentPayload enrollment;
  final StudentPayload student;
  final List<ParentPayload> parents;
  final bool emitDocument;

  const EnrollmentCommand({
    required this.enrollment,
    required this.student,
    required this.parents,
    this.emitDocument = true,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'enrollment': enrollment.toJson(),
    'student': student.toJson(),
    'parents': parents.map((p) => p.toJson()).toList(),
    'emitDocument': emitDocument,
  };

  factory EnrollmentCommand.fromJson(Map<String, dynamic> j) =>
      EnrollmentCommand(
        enrollment: EnrollmentPayload.fromJson(
          j['enrollment'] as Map<String, dynamic>,
        ),
        student: StudentPayload.fromJson(j['student'] as Map<String, dynamic>),
        parents: (j['parents'] as List<dynamic>? ?? const [])
            .map((e) => ParentPayload.fromJson(e as Map<String, dynamic>))
            .toList(),
        emitDocument: (j['emitDocument'] as bool?) ?? true,
      );
}

/// Lot d'agrégats poussés en un seul POST (vidage groupé de l'outbox).
class EnrollmentCommitBatch {
  final List<EnrollmentCommand> items;

  const EnrollmentCommitBatch(this.items);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory EnrollmentCommitBatch.fromJson(Map<String, dynamic> j) =>
      EnrollmentCommitBatch(
        (j['items'] as List<dynamic>? ?? const [])
            .map((e) => EnrollmentCommand.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── Réponse (ACK) ────────────────────────────────────────────────────────────

class AckEnrollment {
  final String id;
  final String? status;
  final String? enrollmentCode;

  const AckEnrollment({required this.id, this.status, this.enrollmentCode});

  factory AckEnrollment.fromJson(Map<String, dynamic> j) => AckEnrollment(
    id: j['id'] as String,
    status: j['status'] as String?,
    enrollmentCode: j['enrollmentCode'] as String?,
  );
}

class AckStudent {
  final String id;
  final String? matriculationNumber;
  final String? email;

  const AckStudent({required this.id, this.matriculationNumber, this.email});

  factory AckStudent.fromJson(Map<String, dynamic> j) => AckStudent(
    id: j['id'] as String,
    matriculationNumber: j['matriculationNumber'] as String?,
    email: j['email'] as String?,
  );
}

class AckParent {
  final String clientId; // provisoire envoyé
  final String id; // canonique serveur → remap
  final String? phoneNumber;

  const AckParent({required this.clientId, required this.id, this.phoneNumber});

  factory AckParent.fromJson(Map<String, dynamic> j) => AckParent(
    clientId: j['clientId'] as String,
    id: j['id'] as String,
    phoneNumber: j['phoneNumber'] as String?,
  );
}

class AckDocument {
  final String id;
  final String? type; // AI
  final String? number; // ETL-AI-…
  final String? verificationToken;

  const AckDocument({
    required this.id,
    this.type,
    this.number,
    this.verificationToken,
  });

  factory AckDocument.fromJson(Map<String, dynamic> j) => AckDocument(
    id: j['id'] as String,
    type: j['type'] as String?,
    number: j['number'] as String?,
    verificationToken: j['verificationToken'] as String?,
  );
}

/// Signal de doublon (Pré↔Première) — informatif, jamais bloquant.
class DuplicateSignal {
  final String? matchedEnrollmentId;
  final String? reason;

  const DuplicateSignal({this.matchedEnrollmentId, this.reason});

  factory DuplicateSignal.fromJson(Map<String, dynamic> j) => DuplicateSignal(
    matchedEnrollmentId: j['matchedEnrollmentId'] as String?,
    reason: j['reason'] as String?,
  );
}

class AckError {
  final String? field;
  final String message;

  const AckError({this.field, required this.message});

  factory AckError.fromJson(Map<String, dynamic> j) => AckError(
    field: j['field'] as String?,
    message: (j['message'] as String?) ?? 'Erreur de validation',
  );
}

/// ACK d'un item du batch, corrélé par [clientEnrollmentId].
class EnrollmentAck {
  final String clientEnrollmentId;
  final String outcome; // COMMITTED | VALIDATION_ERROR
  final AckEnrollment? enrollment;
  final AckStudent? student;
  final List<AckParent> parents;
  final AckDocument? document;
  final DuplicateSignal? duplicateSignal;
  final AckError? error;

  const EnrollmentAck({
    required this.clientEnrollmentId,
    required this.outcome,
    this.enrollment,
    this.student,
    this.parents = const [],
    this.document,
    this.duplicateSignal,
    this.error,
  });

  bool get isCommitted => outcome.toUpperCase() == 'COMMITTED';

  factory EnrollmentAck.fromJson(Map<String, dynamic> j) => EnrollmentAck(
    clientEnrollmentId: j['clientEnrollmentId'] as String,
    outcome: (j['outcome'] as String?) ?? 'VALIDATION_ERROR',
    enrollment: j['enrollment'] == null
        ? null
        : AckEnrollment.fromJson(j['enrollment'] as Map<String, dynamic>),
    student: j['student'] == null
        ? null
        : AckStudent.fromJson(j['student'] as Map<String, dynamic>),
    parents: (j['parents'] as List<dynamic>? ?? const [])
        .map((e) => AckParent.fromJson(e as Map<String, dynamic>))
        .toList(),
    document: j['document'] == null
        ? null
        : AckDocument.fromJson(j['document'] as Map<String, dynamic>),
    duplicateSignal: j['duplicateSignal'] == null
        ? null
        : DuplicateSignal.fromJson(
            j['duplicateSignal'] as Map<String, dynamic>,
          ),
    error: j['error'] == null
        ? null
        : AckError.fromJson(j['error'] as Map<String, dynamic>),
  );
}

/// Résultat du batch : 1 ACK par item, corrélé par `clientEnrollmentId`.
class EnrollmentCommitResult {
  final List<EnrollmentAck> results;

  const EnrollmentCommitResult(this.results);

  EnrollmentAck? forClientEnrollmentId(String id) {
    for (final ack in results) {
      if (ack.clientEnrollmentId == id) return ack;
    }
    return null;
  }

  factory EnrollmentCommitResult.fromJson(Map<String, dynamic> j) =>
      EnrollmentCommitResult(
        (j['results'] as List<dynamic>? ?? const [])
            .map((e) => EnrollmentAck.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
