import 'package:school_app_flutter/core/constants/menu_constants.dart';

class AppRoutesNames {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String home = 'home';
  static const String forgotPasswordEmail = 'forgot-password-email';
  static const String forgotPasswordOtp = 'forgot-password-otp';
  static const String forgotPasswordReset = 'forgot-password-reset';

  // Home sub-routes
  static const String inscriptionsDashboard = '/inscriptions/${MenuConstants.inscriptionsDashboardId}';
  static const String preInscriptions = '/inscriptions/${MenuConstants.preInscriptionsId}';
  static const String reInscriptions = '/inscriptions/${MenuConstants.reInscriptionsId}';
  static const String premiereInscription = '/inscriptions/${MenuConstants.premiereInscriptionId}';

  static const String financesDashboard = '/finances/${MenuConstants.financesDashboardId}';
  static const String facturations = '/finances/${MenuConstants.facturationsId}';
  static const String facturationDetail =
      '/finances/${MenuConstants.facturationsId}/detail/:studentId/:academicYearId';
  static const String facturationPaymentDetail =
      '/finances/${MenuConstants.facturationsId}/payment/:studentId/:academicYearId/:paymentId';

  static String facturationDetailPath({
    required String studentId,
    required String academicYearId,
  }) =>
      '/finances/${MenuConstants.facturationsId}/detail/$studentId/$academicYearId';

  static String facturationPaymentDetailPath({
    required String studentId,
    required String academicYearId,
    required String paymentId,
  }) =>
      '/finances/${MenuConstants.facturationsId}/payment/$studentId/$academicYearId/$paymentId';

  static const String classesDashboard = '/classes/${MenuConstants.classesDashboardId}';
  static const String organisation = '/classes/${MenuConstants.organisationId}';
  static const String classesList = '/classes/${MenuConstants.classesListId}';

  static const String disciplinesDashboard = '/disciplines/${MenuConstants.disciplinesDashboardId}';
  static const String presences = '/disciplines/${MenuConstants.presencesId}';
  static const String disciplinesList = '/disciplines/${MenuConstants.disciplinesListId}';
}