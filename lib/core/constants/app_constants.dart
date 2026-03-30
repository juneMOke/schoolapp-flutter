class AppConstants {
  const AppConstants._();

  static const String baseUrl = 'http://10.0.2.2:8080';
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String generateOtpEndpoint = '/api/v1/auth/otp/generate';
  static const String validateOtpEndpoint = '/api/v1/auth/otp/validate';
  static const String resetPasswordEndpoint = '/api/v1/auth/reset-password';

  static const String enrollmentEndpoint = '/api/v1/enrollments';

  static const String enrollmentDetailEndpoint =
      '/api/v1/enrollments/{enrollmentId}/detail';
  static const String enrollmentSearchByStudentInfoEndpoint =
      '/api/v1/enrollment/search/by-names';
  static const String enrollmentSearchByStudentInfoWithDateOfBirthEndpoint =
      '/api/v1/enrollment/search/by-names-and-dob';

  static const String enrollmentSearchByDateOfBirthEndpoint =
      '/api/v1/enrollment/search/by-date-of-birth';

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
