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

  /// Les dépenses — ce que l'école **décaisse** (`DEPENSES_PLAN.md`). Un menu
  /// propre : la source de fonds est enregistrée mais ne débite aucune caisse
  /// en V1, et le ranger sous Finances laisserait croire le contraire.
  static const String expenseMenuId = 'depenses';

  /// La communication aux parents — les communiqués et leurs modèles. Un menu
  /// propre : ce n'est ni de la scolarité ni de la caisse.
  static const String communicationMenuId = 'communication';

  /// Les ressources humaines — le fichier central des agents de l'école, puis
  /// le Pointage qui le lit ; la Paie a son propre module ([hrPayrollMenuId]). Un menu propre : un
  /// agent n'est ni un élève ni une écriture de caisse.
  static const String hrMenuId = 'ressources-humaines';

  /// RH · Personnel — combien d'agents, qui ils sont, et où est la fiche de
  /// chacun. Un module neuf, posé À CÔTÉ de [hrMenuId] (laissé tel quel) :
  /// il lit le même fichier local, donc la même vérité, mais avec ses propres
  /// écrans.
  static const String hrPersonnelMenuId = 'rh-personnel';

  /// RH · Présences — qui est venu, à quelle heure, et ce qui part à la paie.
  /// Un module neuf, posé après RH · Personnel ; l'onglet Pointage des
  /// [hrMenuId] reste en place à côté (même registre, même verrou).
  static const String hrPresenceMenuId = 'rh-presences';

  /// RH · Paie — le livre du mois, les avances, les arriérés et le barème
  /// (spec « R.H. ▸ Paie », carte des sous-modules). Un module propre, posé
  /// après RH · Présences dont il lit le Pointage clos.
  static const String hrPayrollMenuId = 'rh-paie';

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

  /// « Tickets à imprimer », page imbriquée sous Facturations. Un seul
  /// littéral pour la route ET sa garde (`kNestedRouteAccess`) : renommer l'un
  /// sans l'autre ouvrirait la page en silence.
  static const String ticketsToPrintSegment = 'tickets-a-imprimer';

  /// Tableau de bord du Recouvrement : où en est la dette sur une sélection de
  /// frais, quels groupes décrochent, et ce que coûterait un renvoi.
  static const String recouvrementDashboardId = 'recouvrement-dashboard';

  /// Page nominative du module — le contrôle par frais, qui garde son nom :
  /// c'est lui qui donne les noms là où le tableau de bord pose la question.
  /// Identifiant distinct de celui du menu qui le porte : la route de coquille
  /// vaut `/{menu}/{sousMenu}`, et deux segments identiques n'auraient nommé
  /// qu'une redondance.
  static const String recouvrementControlId = 'recouvrement-controle';

  /// Le tableau de bord : combien la boutique a vendu, quoi, et à quels
  /// élèves. Premier sous-menu — il remplace l'ancien historique des ventes.
  static const String boutiqueDashboardId = 'boutique-tableau-de-bord';

  /// Le guichet — la caisse : catalogue, panier, encaissement. L'identifiant
  /// garde son ancien nom (« achats ») : c'est l'adresse des favoris.
  static const String boutiqueAchatsId = 'boutique-achats';

  /// L'ancien historique des ventes, retiré : son adresse ne sert plus qu'à
  /// rediriger un favori vers le tableau de bord.
  static const String boutiqueLegacyHistoryId = 'boutique-historique';

  /// Tableau de bord des dépenses : combien, sur quoi, ce qui reste à régler.
  static const String expenseDashboardId = 'depenses-tableau-de-bord';

  /// Le registre — « Frais de fonctionnement » : c'est ici, et nulle part
  /// ailleurs, qu'une dépense se crée, se modifie ou se retire.
  static const String expenseRegisterId = 'depenses-frais-fonctionnement';

  /// La file de validation : les demandes qui attendent une décision, de la
  /// plus ancienne à la plus récente. Elle ignore la période des deux autres
  /// écrans — une demande déposée le mois dernier attend toujours.
  static const String expenseQueueId = 'depenses-validations';

  /// Le fichier du personnel : tous les agents de l'école, leur contrat et
  /// leur dossier administratif.
  static const String hrStaffFileId = 'fichier-du-personnel';

  /// Le Pointage du personnel : le registre du jour, la fiche mensuelle d'un
  /// agent et le récapitulatif du mois.
  static const String hrStaffAttendanceId = 'pointage';

  /// RH · Paie ▸ Tableau de bord : prévu et réel, payé et non payé, prêts,
  /// arriérés, et ce que chaque salarié perçoit (spec TB).
  static const String hrPayrollDashboardId = 'paie-tableau-de-bord';

  /// RH · Paie ▸ Paie : le livre du mois, l'état de paie, les bulletins et
  /// l'historique.
  static const String hrPayrollId = 'paie';

  /// RH · Paie ▸ Avances & prêts : les demandes, le registre, l'échéancier.
  static const String hrPayrollAdvancesId = 'paie-avances';

  /// RH · Paie ▸ Arriérés : ce que l'école doit encore à ses agents sur des
  /// paies validées (Paie v2, B4).
  static const String hrPayrollArrearsId = 'paie-arrieres';

  /// RH · Paie ▸ Configuration : le barème de l'école. La direction le
  /// modifie, l'économe le consulte.
  static const String hrPayrollSettingsId = 'paie-configuration';

  /// RH · Personnel ▸ Tableau de bord : l'effectif, sa répartition, et la
  /// liste nominative « Qui sont-ils », exportable en PDF.
  static const String hrPersonnelDashboardId = 'rh-personnel-tableau-de-bord';

  /// RH · Personnel ▸ Fichier du personnel : trouver un agent et ouvrir sa
  /// fiche — sans statistiques, celles-ci vivent au tableau de bord.
  static const String hrPersonnelFileId = 'rh-personnel-fichier';

  /// RH · Présences ▸ Tableau de bord : taux, retards, absences et
  /// assiduité par agent sur une période — en ligne (D1).
  static const String hrPresenceDashboardId = 'rh-presences-tableau-de-bord';

  /// RH · Présences ▸ Fiche individuelle : le profil de présence de chaque
  /// agent, sur le mois ou l'année — en ligne (D1).
  static const String hrPresenceFicheId = 'rh-presences-fiche';

  /// RH · Présences ▸ Récapitulatif : les totaux du mois par agent et sa
  /// clôture — en ligne (D1), la clôture partant par l'outbox.
  static const String hrPresenceRecapId = 'rh-presences-recap';

  /// RH · Présences ▸ Registre du jour : pointer chaque agent, justifier,
  /// valider le rapport — le seul écran du module hors ligne.
  static const String hrPresenceRegisterId = 'rh-presences-registre';

  /// Les communiqués aux parents : rédiger, programmer, envoyer, consulter.
  static const String communicationAnnouncementsId =
      'communication-communiques';

  /// Les modèles de communiqué de l'école.
  static const String communicationTemplatesId = 'communication-modeles';

  static const String classesDashboardId = 'classes-dashboard';
  static const String organisationId = 'organisation';
  static const String classesListId = 'classes-list';

  static const String disciplinesDashboardId = 'disciplines-dashboard';
  static const String presencesId = 'presences';

  /// Les justifications d'absence déposées par les parents (portail parent).
  static const String justificationsId = 'justifications';
  static const String disciplinesListId = 'disciplines-list';

  /// « Mes évaluations » (ex-« Mes cours ») : l'identifiant ne change pas,
  /// seul le libellé du menu a changé.
  static const String myCoursesId = 'my-courses';

  /// « Mes cours » : le programme de chaque cours (chapitres).
  static const String courseProgrammeId = 'course-programme';

  /// « Mon journal » : le journal de classe journalier du professeur.
  static const String classJournalId = 'class-journal';
  static const String timetableId = 'timetable';

  static const String resultatsClasseId = 'resultats-classe';

  static const String documentsStudentId = 'documents-eleve';

  /// ⚠️ Cet identifiant **est** le second segment de la route réelle
  /// (`/configuration/settings`), et non un libellé choisi librement comme les
  /// autres. C'est ce qui rend littéralement vrai le test d'accord
  /// menu ↔ garde de route, qui reconstruit `/{menu}/{sousMenu}`.
  static const String configurationSchoolId = 'settings';
}
