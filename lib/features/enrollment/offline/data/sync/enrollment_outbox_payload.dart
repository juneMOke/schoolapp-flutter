// Format FIGÉ du payload outbox de l'agrégat inscription (écrit par le DAO,
// relu au push). Clés camelCase, dates `yyyy-MM-dd`. La charge réseau réelle en
// est dérivée par `EnrollmentAggregateRequest` (enrollment_aggregate_request.dart).

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

  /// Tuteur à appeler en urgence, pour CET élève. **Tri-état, et les trois
  /// valeurs comptent** : `true` le désigne et démote les autres tuteurs de
  /// l'élève, `false` retire celui-là seulement, `null` ne touche à rien. Un
  /// `false` posé par confort à la place d'un `null` effacerait une désignation
  /// faite ailleurs — d'où le type nullable, conservé jusqu'au fil.
  final bool? emergencyContact;

  const ParentPayload({
    required this.clientId,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.phoneNumber,
    this.email,
    required this.relationshipType,
    this.emergencyContact,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'clientId': clientId,
    'firstName': firstName,
    'lastName': lastName,
    'surname': surname,
    'phoneNumber': phoneNumber,
    'email': email,
    'relationshipType': relationshipType,
    'emergencyContact': emergencyContact,
  };

  factory ParentPayload.fromJson(Map<String, dynamic> j) => ParentPayload(
    clientId: j['clientId'] as String,
    firstName: j['firstName'] as String,
    lastName: j['lastName'] as String,
    surname: j['surname'] as String?,
    phoneNumber: j['phoneNumber'] as String,
    email: j['email'] as String?,
    relationshipType: (j['relationshipType'] as String?) ?? 'OTHER',
    // Absent des payloads écrits avant l'existence du champ : `null` y est la
    // bonne lecture — ces agrégats-là ne désignaient personne, et ne doivent
    // rien démoter au push.
    emergencyContact: j['emergencyContact'] as bool?,
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

  /// Référence d'origine : matricule (RE), id préinscription (PRE), null (NEW).
  /// Nullable + absent des anciens payloads (compat outbox rétroactive).
  final String? sourceRef;
  final String? previousSchoolName;
  final String? previousAcademicYear;
  final String? previousSchoolLevelGroup;
  final String? previousSchoolLevel;
  final double? previousRate;
  final int? previousRank;
  final bool? validatedPreviousYear;

  /// « Ancien élève de cette école », déclaré au guichet — jamais nul, comme la
  /// colonne serveur.
  final bool formerStudent;

  /// Fiche santé de l'enfant. Donnée de santé : ce payload dort en base
  /// chiffrée, mais il ne doit apparaître dans aucun log ni message d'erreur.
  final String? medicalNotes;
  final String? transferReason;
  final String? cancellationReason;

  /// Réductions déclarées au guichet (ADR-021 V1). Codes seuls : le serveur
  /// grave l'octroi, l'horodate et l'attribue à l'auteur de la session — même
  /// principe que `Auditable.createdBy`, le client n'envoie rien de tout ça.
  ///
  /// **Mémoire seule** : aucune créance de ce payload n'en dépend, aucun
  /// montant ne change.
  final List<String> reductionCodes;

  const EnrollmentPayload({
    required this.id,
    required this.enrollmentType,
    required this.status,
    required this.academicYearId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    required this.enrollmentDate,
    this.sourceRef,
    this.previousSchoolName,
    this.previousAcademicYear,
    this.previousSchoolLevelGroup,
    this.previousSchoolLevel,
    this.previousRate,
    this.previousRank,
    this.validatedPreviousYear,
    this.formerStudent = false,
    this.medicalNotes,
    this.transferReason,
    this.cancellationReason,
    this.reductionCodes = const [],
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'enrollmentType': enrollmentType,
    'status': status,
    'academicYearId': academicYearId,
    'schoolLevelId': schoolLevelId,
    'schoolLevelGroupId': schoolLevelGroupId,
    'enrollmentDate': enrollmentDate,
    'sourceRef': sourceRef,
    'previousSchoolName': previousSchoolName,
    'previousAcademicYear': previousAcademicYear,
    'previousSchoolLevelGroup': previousSchoolLevelGroup,
    'previousSchoolLevel': previousSchoolLevel,
    'previousRate': previousRate,
    'previousRank': previousRank,
    'validatedPreviousYear': validatedPreviousYear,
    'formerStudent': formerStudent,
    'medicalNotes': medicalNotes,
    'transferReason': transferReason,
    'cancellationReason': cancellationReason,
    // Omis quand vide, jamais `[]`. Le payload d'outbox se relit tel quel : y
    // écrire une liste vide systématiquement ne dirait rien de plus, et la
    // requête réseau qui en dérive dirait « retire tout » à un serveur qui,
    // aujourd'hui, ne connaît pas encore le champ.
    if (reductionCodes.isNotEmpty) 'reductionCodes': reductionCodes,
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
        sourceRef: j['sourceRef'] as String?,
        previousSchoolName: j['previousSchoolName'] as String?,
        previousAcademicYear: j['previousAcademicYear'] as String?,
        previousSchoolLevelGroup: j['previousSchoolLevelGroup'] as String?,
        previousSchoolLevel: j['previousSchoolLevel'] as String?,
        previousRate: (j['previousRate'] as num?)?.toDouble(),
        previousRank: j['previousRank'] as int?,
        // **Payload écrit avant l'existence du champ** : une inscription
        // confirmée dort peut-être déjà dans l'outbox sans cette clé. Un
        // `as bool` y lèverait et bloquerait la file entière ; on retombe alors
        // sur la seule information que ce payload porte — son type. Même repli
        // que le serveur applique aux postes muets, et pour la même raison.
        formerStudent:
            (j['formerStudent'] as bool?) ??
            (j['enrollmentType'] as String?) == 'RE_ENROLLMENT',
        medicalNotes: j['medicalNotes'] as String?,
        validatedPreviousYear: j['validatedPreviousYear'] as bool?,
        transferReason: j['transferReason'] as String?,
        cancellationReason: j['cancellationReason'] as String?,
        // **Payload écrit avant l'existence du champ** — même piège que
        // `formerStudent` ci-dessus, même remède : une inscription confirmée
        // dort peut-être déjà dans l'outbox sans cette clé, et un `as List` y
        // lèverait en bloquant la file ENTIÈRE, pour un champ qui ne vaut
        // aucun centime.
        reductionCodes: [
          for (final code in (j['reductionCodes'] as List<dynamic>? ?? const []))
            if (code is String) code,
        ],
      );
}

/// Une commande = un agrégat inscription (parent[s] + student + link + enroll).
class EnrollmentCommand {
  final EnrollmentPayload enrollment;
  final StudentPayload student;
  final List<ParentPayload> parents;
  final bool emitDocument;

  /// Uid de l'auteur (ADR-010 D-05), figé à la saisie. Transporté dans le
  /// payload d'outbox puis recopié au top-level de la requête réseau
  /// ([EnrollmentAggregateRequest]). `null` = session héritée sans uid.
  final String? authorId;

  const EnrollmentCommand({
    required this.enrollment,
    required this.student,
    required this.parents,
    this.emitDocument = true,
    this.authorId,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (authorId != null) 'authorId': authorId,
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
        authorId: j['authorId'] as String?,
      );
}
