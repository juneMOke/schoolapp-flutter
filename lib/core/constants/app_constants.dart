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
  static const int offlineDbSchemaVersion = 3;

  /// Clé du secure storage hébergeant la clé de chiffrement SQLCipher,
  /// générée au premier lancement (cf. DatabaseKeyService).
  static const String sqlCipherKeyStorageKey = 'sqlcipher_db_key';

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

  /// Pull delta du grand-livre (créances autoritaires + paiements + allocations).
  static const String syncFinanceLedgerEndpoint = '/api/v1/sync/finance/ledger';

  // ── Offline sync — Classe/Présence/Discipline ──
  /// GET delta des classes + rosters (CB-2). Renvoie les `ref_classrooms` +
  /// `ref_classroom_members` modifiés depuis `updatedSince` (ISO-8601), plus un
  /// `serverCursor` (ISO). Query : `academicYearId`, `updatedSince`.
  /// 304 Not Modified honoré (delta minimal).
  /// ✅ LIVRÉ V1.0 côté back (2026-07-07) — roster ACTIVE+INACTIVE.
  static const String syncClassroomsEndpoint = '/api/v1/sync/classrooms';
}
