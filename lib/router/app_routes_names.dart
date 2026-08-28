import 'package:school_app_flutter/core/constants/menu_constants.dart';

class AppRoutesNames {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String home = 'home';
  static const String forgotPasswordEmail = 'forgot-password-email';
  static const String forgotPasswordOtp = 'forgot-password-otp';
  static const String forgotPasswordReset = 'forgot-password-reset';

  // Home sub-routes
  static const String inscriptionsDashboard =
      '/inscriptions/${MenuConstants.inscriptionsDashboardId}';
  static const String preInscriptions =
      '/inscriptions/${MenuConstants.preInscriptionsId}';
  static const String reInscriptions =
      '/inscriptions/${MenuConstants.reInscriptionsId}';
  static const String premiereInscription =
      '/inscriptions/${MenuConstants.premiereInscriptionId}';

  static const String financesDashboard =
      '/finances/${MenuConstants.financesDashboardId}';
  static const String facturations =
      '/finances/${MenuConstants.facturationsId}';
  static const String facturationDetail =
      '/finances/${MenuConstants.facturationsId}/detail/:studentId/:academicYearId';

  static const String feeControl = '/finances/${MenuConstants.feeControlId}';

  static String facturationDetailPath({
    required String studentId,
    required String academicYearId,
  }) =>
      '/finances/${MenuConstants.facturationsId}/detail/$studentId/$academicYearId';

  static const String classesDashboard =
      '/classes/${MenuConstants.classesDashboardId}';
  static const String organisation = '/classes/${MenuConstants.organisationId}';
  static const String classesList = '/classes/${MenuConstants.classesListId}';

  static const String disciplinesDashboard =
      '/disciplines/${MenuConstants.disciplinesDashboardId}';
  static const String presences = '/disciplines/${MenuConstants.presencesId}';
  static const String disciplinaryStudentDetail =
      '/disciplines/${MenuConstants.presencesId}/student/:studentId/:academicYearId';
  static const String disciplinesList =
      '/disciplines/${MenuConstants.disciplinesListId}';

  static const String myCourses = '/cours/${MenuConstants.myCoursesId}';
  static const String timetable = '/cours/${MenuConstants.timetableId}';

  static const String resultatsClasse =
      '/resultats/${MenuConstants.resultatsClasseId}';

  static const String documentsStudents =
      '/documents/${MenuConstants.documentsStudentId}';

  /// Catalogue des pièces d'un élève. L'année est dans le chemin — comme pour la
  /// facturation — pour qu'un lien profond reste résoluble sans dépendre du
  /// contexte académique en mémoire.
  static const String documentsCatalog =
      '/documents/${MenuConstants.documentsStudentId}'
      '/catalogue/:studentId/:academicYearId';

  static String documentsCatalogPath({
    required String studentId,
    required String academicYearId,
  }) =>
      '/documents/${MenuConstants.documentsStudentId}'
      '/catalogue/$studentId/$academicYearId';

  static String disciplinaryStudentDetailPath({
    required String studentId,
    required String academicYearId,
  }) =>
      '/disciplines/${MenuConstants.presencesId}/student/$studentId/$academicYearId';

  /// Assistant de mise en service de l'école (module Configuration).
  ///
  /// Route de premier niveau, hors coquille : elle doit s'ouvrir alors que
  /// l'école n'a pas encore d'année académique, c'est-à-dire au moment précis où
  /// le reste de l'application n'a rien à montrer.
  static const String configuration = 'configuration';
  static const String configurationPath = '/configuration';

  // Debug — galerie de composants (kDebugMode uniquement)
  static const String componentGallery = '/dev/components';

  // Debug — banc de calage de l'impression thermique (kDebugMode uniquement)
  static const String ticketPrintBench = '/dev/ticket-print';
}
