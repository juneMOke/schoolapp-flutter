class MenuConstants {
  const MenuConstants._();

  // Accueil — page d'atterrissage post-connexion (item feuille, sans sous-menu).
  // Sert d'identifiant de contenu pour `selectedSubMenuId` quand on est sur la
  // page d'accueil (spec Accueil §00/§09).
  static const String accueilId = 'accueil';

  // Menu IDs
  static const String inscriptionsMenuId = 'inscriptions';
  static const String financesMenuId = 'finances';
  static const String classesMenuId = 'classes';
  static const String disciplinesMenuId = 'disciplines';
  static const String coursesMenuId = 'courses';
  static const String resultatsMenuId = 'resultats';

  // Sub-menu IDs
  static const String inscriptionsDashboardId = 'inscriptions-dashboard';
  static const String preInscriptionsId = 'pre-inscriptions';
  static const String reInscriptionsId = 're-inscriptions';
  static const String premiereInscriptionId = 'premiere-inscription';

  static const String financesDashboardId = 'finances-dashboard';
  static const String facturationsId = 'facturations';

  static const String classesDashboardId = 'classes-dashboard';
  static const String organisationId = 'organisation';
  static const String classesListId = 'classes-list';

  static const String disciplinesDashboardId = 'disciplines-dashboard';
  static const String presencesId = 'presences';
  static const String disciplinesListId = 'disciplines-list';

  static const String myCoursesId = 'my-courses';
  static const String timetableId = 'timetable';

  static const String resultatsClasseId = 'resultats-classe';
}
