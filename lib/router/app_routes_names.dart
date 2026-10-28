import 'package:school_app_flutter/core/constants/menu_constants.dart';

class AppRoutesNames {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String home = 'home';
  static const String homePath = '/home';

  /// Un écran de la coquille : `/home/{sousMenu}`.
  ///
  /// Le second segment EST l'identifiant de sous-menu — la garde de
  /// permission (`canAccessLocation`) s'y applique donc sans déclaration
  /// propre. L'Accueil reste `/home` nu.
  static const String homeSubMenu = 'home-sub-menu';
  static const String homeSubMenuRoute = '/home/:subMenuId';

  static String homeSubMenuPath(String? subMenuId) =>
      subMenuId == null ||
          subMenuId.isEmpty ||
          subMenuId == MenuConstants.accueilId
      ? homePath
      : '$homePath/$subMenuId';

  /// La séance photo d'une classe, plein écran (hors coquille).
  static const String photoSession = 'photo-session';
  static const String photoSessionPath = '/student-photo/session';
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

  static String facturationDetailPath({
    required String studentId,
    required String academicYearId,
  }) =>
      '/finances/${MenuConstants.facturationsId}/detail/$studentId/$academicYearId';

  /// Encaissement d'un paiement — écran plein poussé au-dessus de la fiche.
  ///
  /// Sous-route de la fiche : l'élève et l'année sont dans le chemin, et le
  /// contexte d'affichage (identité, classe, créances relues juste avant)
  /// voyage dans `extra`. Sans lui, la page se rabat sur sa carte de contexte
  /// plutôt que d'encaisser au nom d'un inconnu.
  static const String facturationCreatePayment =
      '/finances/${MenuConstants.facturationsId}'
      '/detail/:studentId/:academicYearId/encaissement';

  static String facturationCreatePaymentPath({
    required String studentId,
    required String academicYearId,
  }) =>
      '/finances/${MenuConstants.facturationsId}'
      '/detail/$studentId/$academicYearId/encaissement';

  /// Tickets à imprimer — les tickets que ce poste doit encore sortir, avec le
  /// numéro définitif de leur reçu (continuité des tickets RC, lot D). Écran
  /// plein poussé au-dessus de Facturation, depuis le bandeau d'alerte.
  static const String ticketsToPrint =
      '/finances/${MenuConstants.facturationsId}/tickets-a-imprimer';

  /// Recouvrement — module propre depuis 2026-09-02, renommé le 2026-09-10 :
  /// le chemin ne passe plus par `/finances`, ni par `/controle-frais`.
  static const String recouvrementDashboard =
      '/${MenuConstants.recouvrementMenuId}/${MenuConstants.recouvrementDashboardId}';
  static const String recouvrementControl =
      '/${MenuConstants.recouvrementMenuId}/${MenuConstants.recouvrementControlId}';

  static const String boutiqueAchats =
      '/boutique/${MenuConstants.boutiqueAchatsId}';
  static const String boutiqueDashboard =
      '/boutique/${MenuConstants.boutiqueDashboardId}';
  static const String boutiqueLegacyHistory =
      '/boutique/${MenuConstants.boutiqueLegacyHistoryId}';

  static const String expenseDashboard =
      '/${MenuConstants.expenseMenuId}/${MenuConstants.expenseDashboardId}';
  static const String expenseRegister =
      '/${MenuConstants.expenseMenuId}/${MenuConstants.expenseRegisterId}';
  static const String communicationAnnouncements =
      '/${MenuConstants.communicationMenuId}/${MenuConstants.communicationAnnouncementsId}';
  static const String communicationTemplates =
      '/${MenuConstants.communicationMenuId}/${MenuConstants.communicationTemplatesId}';
  static const String expenseQueue =
      '/${MenuConstants.expenseMenuId}/${MenuConstants.expenseQueueId}';
  static const String hrPersonnelDashboard =
      '/${MenuConstants.hrPersonnelMenuId}/${MenuConstants.hrPersonnelDashboardId}';
  static const String hrPersonnelFile =
      '/${MenuConstants.hrPersonnelMenuId}/${MenuConstants.hrPersonnelFileId}';
  static const String hrPresenceDashboard =
      '/${MenuConstants.hrPresenceMenuId}/${MenuConstants.hrPresenceDashboardId}';
  static const String hrPresenceFiche =
      '/${MenuConstants.hrPresenceMenuId}/${MenuConstants.hrPresenceFicheId}';
  static const String hrPresenceRecap =
      '/${MenuConstants.hrPresenceMenuId}/${MenuConstants.hrPresenceRecapId}';
  static const String hrPresenceRegister =
      '/${MenuConstants.hrPresenceMenuId}/${MenuConstants.hrPresenceRegisterId}';

  /// La fiche d'un agent, par-dessus l'écran de RH · Personnel qui l'a
  /// ouverte (`/home/rh-personnel-fichier/{agentId}`) : F5 et un lien
  /// partagé rouvrent l'écran dans la coquille, et la fiche par-dessus.
  static const String hrPersonnelAgent = '$homeSubMenuRoute/:agentId';

  static String hrPersonnelAgentPath({
    required String subMenuId,
    required String agentId,
  }) => '${homeSubMenuPath(subMenuId)}/${Uri.encodeComponent(agentId)}';
  static const String hrStaffFile =
      '/${MenuConstants.hrMenuId}/${MenuConstants.hrStaffFileId}';
  static const String hrStaffAttendance =
      '/${MenuConstants.hrMenuId}/${MenuConstants.hrStaffAttendanceId}';
  static const String hrPayrollDashboard =
      '/${MenuConstants.hrPayrollMenuId}/${MenuConstants.hrPayrollDashboardId}';
  static const String hrPayroll =
      '/${MenuConstants.hrPayrollMenuId}/${MenuConstants.hrPayrollId}';
  static const String hrPayrollAdvances =
      '/${MenuConstants.hrPayrollMenuId}/${MenuConstants.hrPayrollAdvancesId}';
  static const String hrPayrollArrears =
      '/${MenuConstants.hrPayrollMenuId}/${MenuConstants.hrPayrollArrearsId}';
  static const String hrPayrollSettings =
      '/${MenuConstants.hrPayrollMenuId}/${MenuConstants.hrPayrollSettingsId}';

  static const String classesDashboard =
      '/classes/${MenuConstants.classesDashboardId}';
  static const String organisation = '/classes/${MenuConstants.organisationId}';
  static const String classesList = '/classes/${MenuConstants.classesListId}';

  static const String disciplinesDashboard =
      '/disciplines/${MenuConstants.disciplinesDashboardId}';
  static const String presences = '/disciplines/${MenuConstants.presencesId}';
  static const String justifications =
      '/disciplines/${MenuConstants.justificationsId}';
  static const String disciplinaryStudentDetail =
      '/disciplines/${MenuConstants.presencesId}/student/:studentId/:academicYearId';
  static const String disciplinesList =
      '/disciplines/${MenuConstants.disciplinesListId}';

  static const String myCourses = '/cours/${MenuConstants.myCoursesId}';
  static const String courseProgramme =
      '/cours/${MenuConstants.courseProgrammeId}';
  static const String timetable = '/cours/${MenuConstants.timetableId}';
  static const String classJournal = '/cours/${MenuConstants.classJournalId}';

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

  /// Réglages réouvrables, après mise en service. Même garde que l'assistant :
  /// même geste, même autorité.
  static const String configurationSettings = 'configuration-settings';
  static const String configurationSettingsPath = '/configuration/settings';

  // Debug — galerie de composants (kDebugMode uniquement)
  static const String componentGallery = '/dev/components';

  // Debug — banc de calage de l'impression thermique (kDebugMode uniquement)
  static const String ticketPrintBench = '/dev/ticket-print';
}
