class EnrollmentConstants {
  const EnrollmentConstants._();

  // Routes
  static const String preRegistrationsRoute = '/enrollments/pre-registrations';
  static const String enrollmentDetailRoute = '/enrollments/detail';

  // Search hints
  static const String searchFirstNameHint = 'search_first_name_hint';
  static const String searchLastNameHint = 'search_last_name_hint';
  static const String searchSurnameHint = 'search_surname_hint';
  static const String searchDateOfBirthHint = 'search_date_of_birth_hint';

  // Status
  static const String statusPending = 'status_pending';
  static const String statusValidated = 'status_validated';
  static const String statusRejected = 'status_rejected';

  // Actions
  static const String viewDetails = 'view_details';
  static const String editEnrollment = 'edit_enrollment';
  static const String exportData = 'export_data';
  static const String noResultsFound = 'no_results_found';

  // Dimensions
  static const double cardRadius = 12.0;
  static const double searchFormHeight = 120.0;
  static const double tableRowHeight = 64.0;
  static const double avatarRadius = 20.0;
}