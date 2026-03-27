class AppConstants {
  const AppConstants._();

  static const String baseUrl = 'http://10.0.2.2:8080';
  static const String loginEndpoint = '/api/v1/auth/login';

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
