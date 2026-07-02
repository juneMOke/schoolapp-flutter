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
  static const String enrollmentStudentSummaryEndpoint =
      '/api/v1/enrollments/student-summary';
  static const String enrollmentStatusUpdateEndpoint =
      '/api/v1/enrollments/{enrollmentId}/status';

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
}
