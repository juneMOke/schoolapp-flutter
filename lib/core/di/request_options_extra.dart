class RequestOptionsExtra {
  static Map<String, dynamic> auth() => {'requiresAuth': true};

  static Map<String, dynamic> noAuth() => {'requiresAuth': false};
}
