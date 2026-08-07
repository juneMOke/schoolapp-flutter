/// Type d'inscription (aligné back). Valeurs TEXT exactes en SCREAMING_SNAKE.
enum EnrollmentType {
  newEnrollment('NEW_ENROLLMENT'),
  reEnrollment('RE_ENROLLMENT'),
  preEnrollment('PRE_ENROLLMENT');

  const EnrollmentType(this.apiValue);

  final String apiValue;

  String toApiValue() => apiValue;

  static EnrollmentType fromApiValue(String? value) =>
      switch (value?.toUpperCase()) {
        'RE_ENROLLMENT' => EnrollmentType.reEnrollment,
        'PRE_ENROLLMENT' => EnrollmentType.preEnrollment,
        _ => EnrollmentType.newEnrollment,
      };
}

/// Statut métier d'un dossier d'inscription (axe distinct de `sync_status`).
/// Valeurs TEXT exactes du back.
enum OfflineEnrollmentStatus {
  preRegistered('PRE_REGISTERED'),
  inProgress('IN_PROGRESS'),
  adminCompleted('ADMIN_COMPLETED'),
  financialCompleted('FINANCIAL_COMPLETED'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const OfflineEnrollmentStatus(this.apiValue);

  final String apiValue;

  String toApiValue() => apiValue;

  static OfflineEnrollmentStatus fromApiValue(String? value) =>
      switch (value?.toUpperCase()) {
        'PRE_REGISTERED' => OfflineEnrollmentStatus.preRegistered,
        'ADMIN_COMPLETED' => OfflineEnrollmentStatus.adminCompleted,
        'FINANCIAL_COMPLETED' => OfflineEnrollmentStatus.financialCompleted,
        'COMPLETED' => OfflineEnrollmentStatus.completed,
        'CANCELLED' => OfflineEnrollmentStatus.cancelled,
        _ => OfflineEnrollmentStatus.inProgress,
      };
}

/// Sexe (aligné back : MALE|FEMALE|OTHER). Conservé comme valeur TEXT exacte.
enum OfflineGender {
  male('MALE'),
  female('FEMALE'),
  other('OTHER');

  const OfflineGender(this.apiValue);

  final String apiValue;

  String toApiValue() => apiValue;

  static OfflineGender fromApiValue(String? value) =>
      switch (value?.toUpperCase()) {
        'FEMALE' => OfflineGender.female,
        'OTHER' => OfflineGender.other,
        _ => OfflineGender.male,
      };
}

/// Lien de parenté (aligné back : FATHER|MOTHER|GUARDIAN|GRANDPARENT|OTHER).
enum OfflineRelationshipType {
  father('FATHER'),
  mother('MOTHER'),
  guardian('GUARDIAN'),
  grandparent('GRANDPARENT'),
  other('OTHER');

  const OfflineRelationshipType(this.apiValue);

  final String apiValue;

  String toApiValue() => apiValue;

  static OfflineRelationshipType fromApiValue(String? value) =>
      switch (value?.toUpperCase()) {
        'FATHER' => OfflineRelationshipType.father,
        'MOTHER' => OfflineRelationshipType.mother,
        'GUARDIAN' => OfflineRelationshipType.guardian,
        'GRANDPARENT' => OfflineRelationshipType.grandparent,
        _ => OfflineRelationshipType.other,
      };
}
