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

  // Éditique — le catalogue des pièces d'un élève couvre trois domaines
  // (Scolarité, Finances, Académique), d'où un menu propre plutôt qu'un
  // sous-menu de Finances qui en mentirait sur la portée.
  static const String documentsMenuId = 'documents';

  /// Le recouvrement — un menu PROPRE, et non un sous-menu de Finances.
  /// Finances est le module de l'ARGENT QUI ENTRE : facturer, encaisser, en
  /// rendre compte. Le recouvrement, lui, ne touche à aucun de ces gestes : il
  /// regarde la DETTE — combien il manque, qui décroche, ce que coûterait un
  /// renvoi. C'est une surveillance, pas une opération de caisse, et le ranger
  /// sous Finances laissait croire qu'on pouvait y encaisser.
  ///
  /// Renommé depuis `controle-frais` le 2026-09-10 (RECOUVREMENT_PLAN.md, D2) :
  /// le contrôle par frais n'est plus qu'un des deux écrans du module.
  static const String recouvrementMenuId = 'recouvrement';

  /// La caisse boutique (ADR-020) — un menu PROPRE, et non un sous-menu de
  /// Finances : c'est une caisse **étanche** à la scolarité (I-4), qui n'alimente
  /// aucun poste dû, et la ranger sous Finances laissait croire le contraire.
  /// Elle a d'ailleurs son propre historique, qui n'est pas celui des paiements.
  static const String boutiqueMenuId = 'boutique';

  // Configuration — les réglages de l'école, réouvrables une fois celle-ci en
  // service. L'assistant de mise en service, lui, s'atteint depuis le splash :
  // il précède la coquille, qui n'a rien à afficher sans année académique.
  static const String configurationMenuId = 'configuration';

  // Sub-menu IDs
  static const String inscriptionsDashboardId = 'inscriptions-dashboard';
  static const String preInscriptionsId = 'pre-inscriptions';
  static const String reInscriptionsId = 're-inscriptions';
  static const String premiereInscriptionId = 'premiere-inscription';

  static const String financesDashboardId = 'finances-dashboard';
  static const String facturationsId = 'facturations';

  /// Tableau de bord du Recouvrement : où en est la dette sur une sélection de
  /// frais, quels groupes décrochent, et ce que coûterait un renvoi.
  static const String recouvrementDashboardId = 'recouvrement-dashboard';

  /// Page nominative du module — le contrôle par frais, qui garde son nom :
  /// c'est lui qui donne les noms là où le tableau de bord pose la question.
  /// Identifiant distinct de celui du menu qui le porte : la route de coquille
  /// vaut `/{menu}/{sousMenu}`, et deux segments identiques n'auraient nommé
  /// qu'une redondance.
  static const String recouvrementControlId = 'recouvrement-controle';

  /// Le guichet : catalogue, panier, encaissement.
  static const String boutiqueAchatsId = 'boutique-achats';

  /// Les ventes déjà encaissées, lues **en local seulement** : l'historique
  /// d'une caisse doit se consulter le jour où le réseau manque.
  static const String boutiqueHistoriqueId = 'boutique-historique';

  static const String classesDashboardId = 'classes-dashboard';
  static const String organisationId = 'organisation';
  static const String classesListId = 'classes-list';

  static const String disciplinesDashboardId = 'disciplines-dashboard';
  static const String presencesId = 'presences';
  static const String disciplinesListId = 'disciplines-list';

  static const String myCoursesId = 'my-courses';
  static const String timetableId = 'timetable';

  static const String resultatsClasseId = 'resultats-classe';

  static const String documentsStudentId = 'documents-eleve';

  /// ⚠️ Cet identifiant **est** le second segment de la route réelle
  /// (`/configuration/settings`), et non un libellé choisi librement comme les
  /// autres. C'est ce qui rend littéralement vrai le test d'accord
  /// menu ↔ garde de route, qui reconstruit `/{menu}/{sousMenu}`.
  static const String configurationSchoolId = 'settings';
}
