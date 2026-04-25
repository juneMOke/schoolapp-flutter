class AppConstants {
  const AppConstants._();

  static const String baseUrl = 'http://10.0.2.2:8080';
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
  static const String listPaymentAllocationsByPaymentIdEndpoint =
      '/api/v1/finance/payments/{paymentId}/allocations';
  static const String listPaymentAllocationsByChargeIdEndpoint =
      '/api/v1/finance/student-charges/{chargeId}/allocations';
  static const String updateStudentChargeExpectedAmountEndpoint =
      '/api/v1/finance/student-charges/{studentChargeId}';

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

  // ─── Pagination ────────────────────────────────────────────────────────────
  /// Taille de page par défaut pour les listes d'enrollments.
  static const int enrollmentDefaultPageSize = 10;
}