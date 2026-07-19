class AppConstants {
  const AppConstants._();

  static const String appEnvironmentDefineKey = 'APP_ENV';
  static const String apiBaseUrlDefineKey = 'API_BASE_URL';
  static const String showEnvironmentBannerDefineKey =
      'SHOW_ENVIRONMENT_BANNER';
  static const String enableVerboseNetworkLoggingDefineKey =
      'ENABLE_VERBOSE_NETWORK_LOGGING';
  static const String defaultAppEnvironment = 'dev';

  static const String loginEndpoint = '/api/v1/auth/login';
  static const String refreshEndpoint = '/api/v1/auth/refresh';
  static const String generateOtpEndpoint = '/api/v1/auth/otp/generate';
  static const String validateOtpEndpoint = '/api/v1/auth/otp/validate';
  static const String resetPasswordEndpoint = '/api/v1/auth/reset-password';

  static const String enrollmentEndpoint = '/api/v1/enrollments';

  static const String studentPersonalInfoEndpoint =
      '/api/v1/students/{studentId}/personal-info';

  static const String studentAddressEndpoint =
      '/api/v1/students/{studentId}/address';

  static const String studentAcademicInfoEndpoint =
      '/api/v1/students/{studentId}/academic-info';

  static const String parentUpdateEndpoint = '/api/v1/parents/{parentId}';
  static const String parentCreateEndpoint = '/api/v1/parents';
  static const String parentUnlinkEndpoint =
      '/api/v1/parents/students/{studentId}/{parentId}';

  static const String enrollmentAcademicInfoEndpoint =
      '/api/v1/enrollments/{enrollmentId}/previous-school-info';

  static const String enrollmentDetailEndpoint =
      '/api/v1/enrollments/{enrollmentId}/detail';
  static const String enrollmentSearchByStudentInfoEndpoint =
      '/api/v1/enrollments/search/by-names';
  static const String enrollmentSearchByStudentInfoWithDateOfBirthEndpoint =
      '/api/v1/enrollments/search/by-names-and-dob';

  static const String enrollmentSearchByDateOfBirthEndpoint =
      '/api/v1/enrollments/search/by-date-of-birth';

  static const String enrollmentSearchByAcademicInfoEndpoint =
      '/api/v1/enrollments/search/by-academic-info';

  static const String enrollmentPreviewByStudentEndpoint =
      '/api/v1/enrollments/students/{studentId}/preview';

  static const String enrollmentStatsEndpoint = '/api/v1/enrollment-stats';

  static const String classroomsEndpoint = '/api/v1/classrooms';
  static const String classroomMembersEndpoint =
      '/api/v1/classrooms/{classroomId}/members';
  static const String classroomMemberReassignEndpoint =
      '/api/v1/classrooms/{classroomId}/members/{classroomMemberId}';
  static const String classroomDistributionOverviewEndpoint =
      '/api/v1/classrooms/distribution-overview';
  static const String classroomStatsEndpoint = '/api/v1/classroom-stats';
  static const String classroomsDistributeEndpoint =
      '/api/v1/classrooms/distribute';

  static const String academicYearBySchoolEndpoint =
      '/api/v1/academic-years/current';

  static const String bootstrapEndpoint = '/api/v1/bootstrap';
  static const String bootstrapCurrentYearEndpoint =
      '/api/v1/bootstrap/current-year';
  static const String bootstrapPreviousYearEndpoint =
      '/api/v1/bootstrap/previous-year';
  static const String feeTariffsEndpoint = '/api/v1/finance/tariffs';
  static const String initializeStudentChargesEndpoint =
      '/api/v1/finance/student-charges/{studentId}/initialize-charges';
  static const String listStudentChargesByStudentAndAcademicYearEndpoint =
      '/api/v1/finance/student-charges/student/{studentId}/academic-year/{academicYearId}';
  static const String listPaymentsByStudentAndAcademicYearEndpoint =
      '/api/v1/finance/payments/student/{studentId}/academic-year/{academicYearId}';
  static const String createPaymentEndpoint = '/api/v1/finance/payments';
  static const String listPaymentAllocationsByPaymentIdEndpoint =
      '/api/v1/finance/payments/{paymentId}/allocations';
  static const String listPaymentAllocationsByChargeIdEndpoint =
      '/api/v1/finance/student-charges/{chargeId}/allocations';
  static const String updateStudentChargeExpectedAmountEndpoint =
      '/api/v1/finance/student-charges/{studentChargeId}';
  static const String financeStatsEndpoint = '/api/v1/finance-stats';

  static const String bootstrapPayloadKey = 'bootstrap_payload';
  static const String bootstrapSchemaVersionKey =
      'bootstrap_local_schema_version';
  static const String bootstrapSchemaVersion = '1';

  static const String accessTokenKey = 'access_token';
  static const String tokenTypeKey = 'token_type';
  static const String expiresInKey = 'expires_in';
  // ADR-010 — secrets de session offline (jamais en base : survivent au wipe).
  static const String refreshTokenKey = 'refresh_token';
  static const String accessExpiresAtKey = 'access_expires_at';
  static const String refreshExpiresAtKey = 'refresh_expires_at';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userFirstNameKey = 'user_first_name';
  static const String userLastNameKey = 'user_last_name';
  static const String userRoleKey = 'user_role';
  static const String userSchoolIdKey = 'user_school_id';
  static const String userCreatedAtKey = 'user_created_at';

  static const String bootstrapPreviousYearPayloadKey =
      'bootstrap_previous_year_payload';

  // ─── Support / Contact ───────────────────────────────────────────────────────
  /// Adresse de contact de l'administration (actions « Contacter l'administrateur »
  /// des etats d'erreur 403). Centralisee ici pour eviter la duplication.
  static const String supportEmail = 'support@school.local';

  // ─── Attendance ────────────────────────────────────────────────────────────
  static const String attendanceEndpoint = '/api/v1/attendances';
  static const String attendanceByClassroomEndpoint =
      '/api/v1/attendances/classes/{classroomId}';
  static const String attendanceStudentSummaryEndpoint =
      '/api/v1/attendance-stats/students/{studentId}/summary';
  static const String attendanceOverviewEndpoint =
      '/api/v1/attendance-stats/overview';
  static const String disciplinaryCasesEndpoint = '/api/v1/disciplinary-cases';
  static const String disciplinaryCaseByIdEndpoint =
      '/api/v1/disciplinary-cases/{caseId}';

  // ─── Academics ───────────────────────────────────────────────────────────
  /// Cours de l'enseignant connecté, regroupés par classe (résolu via le JWT).
  static const String myCoursesEndpoint = '/api/v1/academics/cours/mes-cours';

  /// Détail de notation d'un cours par période (semestre/trimestre) puis
  /// sous-période. `{coursId}` est résolu via `@Path`.
  static const String coursNotationDetailEndpoint =
      '/api/v1/academics/cours/{coursId}/notation';

  /// Création d'une évaluation (interro/devoir/examen) sous un cours.
  /// `{coursId}` est résolu via `@Path` ; l'école vient du JWT (multi-tenant).
  static const String createEvaluationEndpoint =
      '/api/v1/academics/cours/{coursId}/evaluations';

  /// Grille de saisie : chaque élève de la classe du cours + sa note pour
  /// l'évaluation `{evaluationId}` (résolu via `@Path`).
  static const String notesElevesEndpoint =
      '/api/v1/academics/evaluations/{evaluationId}/notes/eleves';

  /// Saisie/rattrapage (upsert idempotent) de la note d'un élève pour
  /// l'évaluation `{evaluationId}` (résolu via `@Path`).
  static const String saisirNoteEndpoint =
      '/api/v1/academics/evaluations/{evaluationId}/notes';

  // ─── Résultats par classe (lecture seule, calcul live) ─────────────────────
  /// Vue classe (synthèse + table roster × sous-période) pour une grande
  /// période. `classroomId`, `periodeScolaireId` et `seuil?` en query.
  static const String resultatsClasseEndpoint =
      '/api/v1/academics/resultats/classe';

  /// Vue focus d'un élève. `{studentId}` résolu via `@Path` ; `classroomId` et
  /// `periodeScolaireId` en query.
  static const String resultatFocusEndpoint =
      '/api/v1/academics/resultats/classe/{studentId}';

  /// Recherche roster scopée classe (mode « Par élève »). `{classroomId}`
  /// résolu via `@Path` ; `academicYearId` requis + `nom`/`postnom`/`prenom`.
  static const String classroomMembersSearchEndpoint =
      '/api/v1/classrooms/{classroomId}/members/search';

  /// Grandes périodes (trimestres/semestres) **d'une classe**, chaque entrée
  /// portant le `periodeScolaireId` exigé par la vue classe / focus, la période
  /// `courant` marquée, et un `libelle` déjà synthétisé côté serveur.
  ///
  /// Scopé **classe** (`classroomId` requis) : le backend résout l'année × cycle
  /// depuis la classe. Trié par `ordre` asc. Auth JWT (`@Extras() requiredAuth`).
  static const String resultatsPeriodesEndpoint =
      '/api/v1/academics/resultats/periodes';

  // ─── Schedule (emploi du temps) ────────────────────────────────────────────
  /// Emploi du temps de l'enseignant connecté (résolu via le JWT).
  static const String myTimetableEndpoint = '/api/v1/schedule/my-timetable';

  /// Grille d'une classe (conseil pédagogique / admin).
  static const String classroomGridEndpoint = '/api/v1/schedule/grid';

  /// Création d'un créneau de sonnerie (une ligne de la grille).
  static const String timeSlotsEndpoint = '/api/v1/schedule/time-slots';

  /// Placement d'un cours à l'emploi du temps.
  static const String sessionsEndpoint = '/api/v1/schedule/sessions';

  /// Retrait d'une séance. `{id}` est résolu via `@Path`.
  static const String sessionByIdEndpoint = '/api/v1/schedule/sessions/{id}';

  // ─── Pagination ────────────────────────────────────────────────────────────
  /// Taille de page par défaut pour les listes d'enrollments.
  static const int enrollmentDefaultPageSize = 10;

  // ─── Offline / Socle local chiffré ───────────────────────────────────────────
  /// Nom du fichier de la base locale chiffrée (SQLCipher).
  static const String offlineDbName = 'school_offline.db';

  /// Version du schéma sqflite local. Bump = nouvelle étape de migration
  /// (onUpgrade dans AppDatabase). V1 = création greenfield.
  // v2 (2026-07-08) : tables de référence Inscription (cohorte RE
  // `ref_previous_year_students`, `ref_pre_enrollments`, socle référentiel).
  // v3 (2026-07-08) : `enrollments.source_ref` (matricule RE / id préinscription
  // PRE, contrat agrégat).
  // v4 (2026-07-16) : Présence — modèle session-agrégat (`attendance_sessions`).
  // v5 (2026-07-18) : Classe — événement `classroom_transfers` (transfert offline).
  // v6 (2026-07-18) : Discipline — agrégat {case, comments[]} : table
  // `disciplinary_case_comments` (append-only) + `disciplinary_cases.server_updated_at`
  // (visibilité serveur, base du pull keyset). Table neuve → aucun backfill.
  // v7 (2026-07-19) : Auth/session offline (ADR-010) — tables `auth_local_user`,
  // `auth_local_session`, `auth_clock_guard`. Tables neuves → aucun backfill.
  // v8 (2026-07-19) : Notes / Cours (academics + schedule, ADR-006) — réf
  // `ref_time_slots`/`ref_recurring_sessions`/`ref_cours` + écriture `evaluation`
  // (régime A) et `note_evaluation` (régime C). Tables neuves → aucun backfill.
  // v9 (2026-07-19) : Notes / Cours — cache `ref_cours_notation` (squelette
  // période/sous-période + statut + effectif). Table neuve → aucun backfill.
  static const int offlineDbSchemaVersion = 9;

  /// Clé du secure storage hébergeant la clé de chiffrement SQLCipher,
  /// générée au premier lancement (cf. DatabaseKeyService).
  static const String sqlCipherKeyStorageKey = 'sqlcipher_db_key';

  // ─── Auth/session offline — dégradation graduée (ADR-010 D-08) ────────────────
  /// Seuil J7 : au-delà de `now − last_server_seen_at`, la session passe en
  /// WARNING (saisie OK, bandeau permanent, scellement de documents bloqué).
  static const Duration sessionWarningThreshold = Duration(days: 7);

  /// Seuil J21 : au-delà, la session passe en READ_ONLY (lecture seule,
  /// reconnexion online exigée).
  static const Duration sessionReadOnlyThreshold = Duration(days: 21);

  // ─── Offline sync — contrats miroir backend ──────────────────────────────────
  // État au 2026-07-07 (cf. ETAT_IMPLEMENTATION_Backend_V1.md, OFFLINE_GAP_ANALYSIS.md) :
  //  • LIVRÉS V1.0 (consommables) : GET /api/v1/sync/classrooms (+ attendance,
  //    academics/cours, academics/notes, schedule — à déclarer ici lors de leur
  //    branchement, cf. Phase 1/3 du plan d'alignement).
  //  • NON livrés (V1.1, câblage miroir en attente) : l'agrégat d'inscription, le
  //    référentiel/cohorte/pré-inscriptions et les pulls finance ci-dessous.
  // Câblés côté client conformément aux SPEC_Frontend_*_Offline_V1.

  // ── Offline sync — Inscription (contrat openapi_enrollment_sync.yaml) ──
  // Contrat que le back met en place. Convention app : préfixe /api/v1
  // (le contrat OpenAPI l'abrège en /api).
  //
  // PUSH (commit agrégat) + PULL delta descendant partagent le chemin de la
  // ressource de synchro `syncEnrollmentsEndpoint` (/api/v1/sync/enrollments) :
  //  • POST → commit {enrollment, student, parents} (201/200 = OK, 422 = rejet).
  //  • GET  → delta descendant (curseur updatedSince → 304).
  // Le pull HYDRATANT (agrégats complets, tablette neuve) est servi à part par
  // `syncEnrollmentSnapshotsEndpoint` (/api/v1/sync/enrollments/snapshots).

  /// Pull du socle référentiel (années, cycles, niveaux, tarifs) — bundle
  /// conditionnel ETag/304. GET /api/v1/sync/referential.
  static const String syncReferentialEndpoint = '/api/v1/sync/referential';

  /// Pull de la cohorte de réinscription N-1 (bornée/statique, ETag/304)
  /// → `ref_previous_year_students`. GET /api/v1/sync/reenrollment-cohort.
  static const String syncReenrollmentCohortEndpoint =
      '/api/v1/sync/reenrollment-cohort';

  /// Pull des préinscriptions en ligne (delta `updatedSince`)
  /// → `ref_pre_enrollments`. GET /api/v1/sync/pre-enrollments.
  static const String syncPreEnrollmentsEndpoint =
      '/api/v1/sync/pre-enrollments';

  /// Pull des inscriptions en ligne (delta maigre `updatedSince`, réconciliation)
  /// + PUSH agrégat idempotent. → `enrollments`. GET/POST /api/v1/sync/enrollments.
  static const String syncEnrollmentsEndpoint = '/api/v1/sync/enrollments';

  /// Pull HYDRATANT des inscriptions (agrégats complets = inscription + élève
  /// canonique + tuteurs) pour reconstituer une tablette neuve (delta
  /// `updatedSince`). GET /api/v1/sync/enrollments/snapshots.
  static const String syncEnrollmentSnapshotsEndpoint =
      '/api/v1/sync/enrollments/snapshots';

  /// Pull delta de la grille tarifaire (gelée sur la saison, 304 fréquent).
  static const String syncFinanceTariffsEndpoint =
      '/api/v1/sync/finance/tariffs';

  /// Pull KEYSET des créances élèves (le plus gros volume ; paginé, résumable,
  /// jeton `cursor` opaque base64url, 304 applicatif). Contrat openapi_billing_sync.
  static const String syncStudentChargesEndpoint =
      '/api/v1/sync/student-charges';

  /// Agrégat paiement offline (contrat openapi_billing_sync) :
  ///  - **POST** = push idempotent de l'encaissement (uuid client honoré) ;
  ///  - **GET** = pull KEYSET des paiements, y compris ceux de l'autre poste de
  ///    perception (anti-divergence de snapshot) — même enveloppe keyset.
  ///
  /// À ne pas confondre avec [createPaymentEndpoint], le POST **en ligne** du
  /// module Facturation (forme à plat), qui reste en service hors offline.
  static const String syncPaymentsEndpoint = '/api/v1/sync/payments';

  // ── Offline sync — Classe/Présence/Discipline ──
  /// Agrégat d'appel Présence (contrat openapi_attendance_sync 1.2.0) :
  ///  - **POST** = push de l'agrégat `{session, absences[]}` (upsert clé
  ///    naturelle + LWW `updatedAt` ; réponse `lwwOutcome` + `expectedCount`) ;
  ///  - **GET** = pull KEYSET des sessions (absences imbriquées), cadré année,
  ///    jeton `cursor` opaque, 304 applicatif.
  ///
  /// Remplace l'ancien push record-level [attendanceEndpoint] côté offline
  /// (celui-ci reste en service pour les lectures online hors offline).
  static const String syncAttendanceEndpoint = '/api/v1/sync/attendance';

  /// GET delta des classes + rosters (CB-2). Renvoie les `ref_classrooms` +
  /// `ref_classroom_members` modifiés depuis `updatedSince` (ISO-8601), plus un
  /// `serverCursor` (ISO). Query : `academicYearId`, `updatedSince`.
  /// 304 Not Modified honoré (delta minimal).
  /// ✅ LIVRÉ V1.0 côté back (2026-07-07) — roster ACTIVE+INACTIVE.
  static const String syncClassroomsEndpoint = '/api/v1/sync/classrooms';

  /// Volet transfert du module Classe (contrat openapi_classroom_sync 1.1.0) :
  ///  - **POST** = push de l'événement de transfert (régime A, idempotent sur
  ///    `transfer.id` ; réponse = appartenance canonique + compteurs des 2
  ///    classes recalculés). 201 créé ≡ 200 rejeu, les deux succès ;
  ///  - **GET** = pull KEYSET des transferts de l'année (dont ceux faits online
  ///    par le conseil pédagogique), cadré année, jeton `cursor` opaque, 304
  ///    applicatif. Indispensable au dénominateur d'assiduité par intervalles.
  static const String syncClassroomTransfersEndpoint =
      '/api/v1/sync/classroom-transfers';

  /// Volet Discipline offline (contrat openapi_discipline_sync 1.1.0) :
  ///  - **POST** = push de l'agrégat `{case, comments[]}` (upsert 200) : le FAIT
  ///    insert-only (régime A, uuid honoré), le TRAITEMENT `status`/`sanction`
  ///    gardé par LWW `clientUpdatedAt`, les commentaires append-only ; la réponse
  ///    porte `lwwOutcome` (APPLIED/SUPERSEDED) + l'état canonique ;
  ///  - **GET** = pull KEYSET des cas de l'année (commentaires imbriqués), cadré
  ///    année, jeton `cursor` opaque, 304 applicatif.
  ///
  /// Remplace côté offline l'ancien couple [disciplinaryCasesEndpoint] (POST) +
  /// [disciplinaryCaseByIdEndpoint] (PUT) : chemin unique upsert, sémantique LWW.
  static const String syncDisciplinaryCasesEndpoint =
      '/api/v1/sync/disciplinary-cases';

  // ── Offline sync — Notes / Cours (contrat PLAN_notes_cours_offline) ──
  // Frontière ADR-006 : seules la SAISIE (évaluation régime A, note régime C)
  // et sa RÉFÉRENCE (cours, emploi du temps) transitent ; bulletin, rang et
  // résultats « live » restent serveur. 5 pulls keyset (lecture seule) + 2
  // ingest. Jeton `cursor` opaque, `KeysetPage`, 304 applicatif sur cycle vide.

  /// Pull KEYSET des cours d'une classe (réf, lecture seule). Query :
  /// `classroomId`, `cursor`, `limit`. → `ref_cours`.
  static const String syncAcademicsCoursEndpoint =
      '/api/v1/sync/academics/cours';

  /// Pull KEYSET **et** ingest des évaluations (régime A, insert-only) :
  ///  - **GET** = delta keyset des évaluations d'un cours (`coursId`, `cursor`,
  ///    `limit`) → `evaluation` ;
  ///  - **POST** = push idempotent d'une évaluation (uuid client honoré) :
  ///    200 rejeu / 201 créée.
  static const String syncAcademicsEvaluationsEndpoint =
      '/api/v1/sync/academics/evaluations';

  /// Pull KEYSET **et** ingest des notes (régime C, upsert clé naturelle + LWW) :
  ///  - **GET** = delta keyset des notes d'un cours (`coursId`, `cursor`,
  ///    `limit`) → `note_evaluation` (curseur INDÉPENDANT de celui des
  ///    évaluations — split assumé) ;
  ///  - **POST** = push d'un lot de notes d'une évaluation ; réponse = **outcome
  ///    par ligne** (APPLIED / SUPERSEDED / REJECTED:PERIODE_CLOSE|INVALID) +
  ///    l'état serveur. Toujours 200.
  static const String syncAcademicsNotesEndpoint =
      '/api/v1/sync/academics/notes';

  /// Pull KEYSET de la trame horaire de l'école (réf, lecture seule). Scope
  /// école résolu par le JWT. Query : `cursor`, `limit`. → `ref_time_slots`.
  static const String syncScheduleTimeSlotsEndpoint =
      '/api/v1/sync/schedule/time-slots';

  /// Pull KEYSET des séances récurrentes de l'année (réf, lecture seule ; labels
  /// dénormalisés). Query : `academicYearId`, `cursor`, `limit`.
  /// → `ref_recurring_sessions`.
  static const String syncScheduleSessionsEndpoint =
      '/api/v1/sync/schedule/sessions';
}
