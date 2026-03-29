class AppConstants {
  const AppConstants._();

  static const String baseUrl = 'http://10.0.2.2:8080';
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String generateOtpEndpoint = '/api/v1/auth/otp/generate';
  static const String validateOtpEndpoint = '/api/v1/auth/otp/validate';
  static const String resetPasswordEndpoint = '/api/v1/auth/reset-password';

  static const String preRegistrationsEndpoint =
      '/api/v1/enrollment/pre-registrations';
  static const String studentsSearchEndpoint =
      '/api/v1/enrollment/students/search';
  static const String studentDetailEndpoint =
      '/api/v1/enrollment/students/{enrollmentId}';
  static const String schoolLevelGroupsEndpoint =
      '/api/v1/enrollment/school-level-groups';
  static const String schoolLevelsEndpoint = '/api/v1/enrollment/school-levels';
  static const String academicFeesEndpoint = '/api/v1/enrollment/academic-fees';

  static const String accessTokenKey = 'access_token';
  static const String tokenTypeKey = 'token_type';
  static const String expiresInKey = 'expires_in';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userFirstNameKey = 'user_first_name';
  static const String userLastNameKey = 'user_last_name';
  static const String userRoleKey = 'user_role';
  static const String userCreatedAtKey = 'user_created_at';
}
