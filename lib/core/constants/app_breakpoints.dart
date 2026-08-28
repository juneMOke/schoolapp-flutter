class AppBreakpoints {
  const AppBreakpoints._();

  // Global responsive breakpoints (single source of truth).
  static const double detailCompactMax = 760.0;
  static const double navigationCompactMax = 1024.0;
  static const double dataTableCardsMax = 600.0;
  static const double fabExtendedMinWidth = dataTableCardsMax;
  static const double tableFooterStackMax = 560.0;
  static const double dataTablePhoneMax = 390.0;
  static const double enrollmentTableGridSwitchMax = dataTableCardsMax;
  static const double authWideMin = 800.0;

  /// Assistant de mise en service — deux bascules seulement.
  ///
  /// À [configurationGridMax] les grilles de champs passent de quatre colonnes
  /// à deux, puis à une sous [configurationCompactMax] ; c'est aussi là que le
  /// stepper se réduit à ses seules pastilles. Un libellé tronqué au tiers ne
  /// dit rien de plus qu'un numéro et prend la place du contenu.
  static const double configurationGridMax = 900.0;
  static const double configurationCompactMax = 560.0;
  // Connexion (spec §01) — split deux panneaux ≥ 900 ; empilé 560–900 ;
  // bandeau slim (lockup seul) < 560.
  static const double loginSplitMin = 900.0;
  static const double loginStackedMin = 560.0;
  static const double formMediumMin = 860.0;
  static const double formWideMin = 1280.0;

  // Première inscription — au-delà (tablette paysage 1280×800+), l'action de
  // création quitte le FAB flottant (qui masquait la pagination) pour devenir
  // un bouton inline sous le tableau. Seuil dédié (découplé de formWideMin).
  static const double enrollmentInlineCreateMin = formWideMin;

  // Étape Tuteurs — en-tête (titre + bouton « Ajouter un tuteur »). Au-delà :
  // titre et bouton sur une même ligne (Row). En deçà (téléphone) : empilés,
  // bouton pleine largeur, sinon le titre serait écrasé/illisible.
  static const double guardianHeaderRowMin = 520.0;

  // Pied d'actions du stepper d'inscription. En deçà (téléphone) : boutons en
  // icônes seules (Précédent / Enregistrer / Suivant) pour éviter l'overflow ;
  // au-delà : boutons avec labels + indicateur d'état.
  static const double stepperControlsCompactMax = 600.0;

  // Étape Frais — tableau des frais. En deçà (téléphone) : colonne Actions
  // (icône edit/lock) masquée → 2 colonnes (Libellé | Montant) pour que le
  // montant ne soit pas tronqué. Au-delà : 3 colonnes.
  static const double studentChargesActionColMin = 480.0;

  // Facturation — seuils responsive dédiés (spec §00 : occupation de l'espace).
  // Au-delà : la page détail élargit son contenu et juxtapose Paiements | Frais.
  static const double financeDetailTwoColMin = navigationCompactMax; // 1024
  // Dashboard stats : juxtapose Évolution | Répartition par frais au-delà.
  static const double financeStatsTwoColMin = 1100.0;
  // Section par type de frais : 2 colonnes / 3 colonnes (valeurs conservées).
  static const double financeStatsFeeTypeTwoColMin = 640.0;
  static const double financeStatsFeeTypeThreeColMin = 980.0;
  // Pied de modale : en deçà, les deux boutons s'empilent (sinon Row).
  static const double financeModalFooterRowMin = 360.0;
  // Contrôle des frais — table à 7 colonnes (identité + attendu/payé/reste +
  // statut). En deçà, les colonnes de montant seraient tronquées par l'ellipse :
  // on replie sur 3 colonnes et Attendu/Payé passent en ligne secondaire.
  //
  // ⚠️ Plafond dur : `AppPageBackground` borne son contenu à
  // `AppDimensions.detailContentMaxWidth` (1180) — un seuil au-delà rendrait la
  // disposition large **inatteignable**, quelle que soit la taille de l'écran.
  static const double feeControlTableWideMin = financeDetailTwoColMin; // 1024
  // Composition des classes — vue répartie.
  // Bandeau de synthèse : au-delà, KPI et basculeur sur une même ligne ;
  // en deçà, le basculeur passe dessous.
  static const double classesSummaryBandRowMin = 860.0;
  // Grille de cartes de classe : 2 colonnes / 3 colonnes.
  static const double classesGridTwoColMin = 700.0;
  static const double classesGridThreeColMin = 1080.0;
  // Cascade Cycle/Niveau : au-delà, les 2 selects côte à côte ; en deçà, empilés.
  static const double classesCascadeRowMin = 520.0;
  // Tuile élève : en deçà, le bouton d'action passe en icône seule (+ tooltip).
  static const double classesMemberTileCompactMax = 300.0;

  // Carte de cas disciplinaire — pied (frise + action). En deçà : empilement
  // vertical pour éviter tout débordement ; au-delà : frise et action en Row.
  static const double disciplinaryCardFooterStackMax = 480.0;

  // Tableau de bord des présences (Disciplines) — la paire 1fr/1fr
  // (Jour/Top classes) passe en colonne sous ce seuil.
  static const double attendanceOverviewTwoColMin = 880.0;
  // Paire large Évolution(2fr)/Motifs(1fr) : reste côte à côte plus haut, pour
  // que le donut Motifs (1fr) ait assez de place avant de s'empiler.
  static const double attendanceOverviewWideTwoColMin = 920.0;
  // Donut des motifs : bascule en disposition Row (donut + légende listée
  // motif·%·effectif) dès cette largeur utile — découplé de detailCompactMax
  // (pensé pour les panneaux pleine largeur), adapté à un panneau 1fr.
  static const double reasonDonutRowMin = 300.0;

  // Emploi du temps — vue par défaut. En deçà (téléphone / petit écran), on ouvre
  // en mode Jour : la grille hebdomadaire (5 jours) y est trop serrée. Au-delà,
  // mode Semaine. L'utilisateur peut toujours basculer via la barre.
  static const double scheduleWeekDefaultMin = dataTableCardsMax; // 600

  // ---------------------------------------------------------------------------
  // Seuils de HAUTEUR (les seuls du fichier — tous les autres portent sur la
  // largeur). Le clavier logiciel n'ouvre pas un panneau par-dessus l'écran :
  // il retire sa hauteur au body (`resizeToAvoidBottomInset`). En paysage il ne
  // reste qu'une centaine de dp au parcours d'inscription, quand sa barre
  // d'étapes, ses marges et son pied en coûtent près de deux cents.
  // ---------------------------------------------------------------------------

  // Parcours d'inscription — au-dessus, chrome complet (barre d'étapes avec
  // chips et libellés, marges pleines).
  static const double wizardStepperFullChromeMinHeight = 420.0;
  // En deçà, même la barre réduite à sa progression prend la place du champ en
  // cours de saisie : elle disparaît et seul le pied d'actions subsiste.
  static const double wizardStepperBreadcrumbMinHeight = 150.0;
}
