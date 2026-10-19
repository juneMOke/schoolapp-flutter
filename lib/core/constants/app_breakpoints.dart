class AppBreakpoints {
  const AppBreakpoints._();

  // Global responsive breakpoints (single source of truth).

  /// Paliers génériques de grand écran, mesurés sur la fenêtre ou sur la
  /// largeur reçue. Les seuils propres à un écran s'y rattachent quand ils
  /// disent la même chose (« assez large pour deux colonnes »).
  static const double expanded = 1280.0;
  static const double large = 1600.0;
  static const double xlarge = 1920.0;

  static const double detailCompactMax = 760.0;
  static const double navigationCompactMax = 1024.0;

  /// Fenêtre sous laquelle le menu de la coquille n'existe qu'en tiroir
  /// (téléphone, 7" portrait). Entre ce seuil et [navigationCompactMax]
  /// (10" portrait, 7" paysage), il reste à l'écran en rail de 84 dp : un
  /// appui par navigation au lieu de deux.
  static const double navigationDrawerMax = detailCompactMax;

  /// Deux volets côte à côte (panier | catalogue, liste | détail) : 420 de
  /// volet + 24 d'écart + ~530 pour l'autre. Tient dans les 1 000 dp qu'une
  /// 10" paysage laisse au contenu barre latérale dépliée (1 280 − 280) —
  /// l'ancien seuil de 1 024 les en privait.
  static const double sideBySideMin = 976.0;

  /// Fenêtre sous laquelle la barre latérale s'ouvre repliée (rail), tant que
  /// l'utilisateur n'a rien choisi : à 1 280, ses 280 dp laissaient au
  /// contenu moins de 1 000 dp.
  static const double sidebarExpandedDefaultMin = 1366.0;
  static const double dataTableCardsMax = 600.0;
  static const double fabExtendedMinWidth = dataTableCardsMax;
  static const double tableFooterStackMax = 560.0;
  static const double dataTablePhoneMax = 390.0;

  /// Téléphone étroit : marges de page resserrées en deçà.
  static const double phoneNarrowMax = 420.0;

  /// Modale de téléphone : marges latérales resserrées jusqu'à ce seuil.
  static const double dialogCompactMax = 560.0;

  /// Grille de champs d'un formulaire (sur la largeur de sa carte) : deux
  /// colonnes au-delà de [formGridTwoColMin], trois au-delà de
  /// [formGridThreeColMin].
  static const double formGridTwoColMin = 560.0;
  static const double formGridThreeColMin = 880.0;

  /// En-tête de page à chiffres (Classes) : en deçà, le titre passe au-dessus
  /// des chiffres au lieu de les serrer.
  static const double pageHeroRowMin = 720.0;

  /// Carte de réglage à trois champs (taux de change) : sur une ligne au-delà.
  static const double settingsFieldsRowMin = 640.0;
  static const double enrollmentTableGridSwitchMax = dataTableCardsMax;
  static const double authWideMin = 800.0;

  // Panneau d'options d'un select (`EteeloSelectPanelMode.adaptive`). Au-delà,
  // popover ancré sous le champ : le formulaire reste visible autour du choix,
  // et la liste s'ouvre là où l'œil est déjà. En deçà, feuille modale — un
  // popover y serait à la fois trop étroit pour lire un libellé entier et trop
  // bas pour être atteint au pouce.
  static const double selectPopoverMin = detailCompactMax;
  // Feuille du bas ⇄ modale centrée (`showEteeloAdaptiveSheet`) : le même seuil
  // que le sélecteur, pour qu'une même largeur donne la même forme à tout.
  static const double adaptiveSheetDialogMin = selectPopoverMin;

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
  static const double formWideMin = expanded;

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
  static const double financeDetailTwoColMin = sideBySideMin;
  // Pied de modale : en deçà, les deux boutons s'empilent (sinon Row).
  static const double financeModalFooterRowMin = 360.0;
  // Barre d'encaissement de la page « Encaisser un paiement » : au-delà, le
  // total et le bouton tiennent sur une même ligne ; en deçà, le bouton passe
  // sous le total et prend toute la largeur — le CTA d'un guichet ne se
  // discute pas avec un montant pour quelques dizaines de dp.
  static const double financeCollectBarRowMin = 640.0;
  // Encaissement (page plein écran, hors coquille) : au-delà, les créances à
  // gauche, le payeur et la date en colonne à droite.
  static const double paymentTwoColumnMin = expanded;
  // Facturation (largeur reçue) : au-delà, la fiche de l'élève s'ouvre à côté
  // de la liste — 440 de liste, ~940 de fiche, assez pour ses deux colonnes.
  static const double facturationSplitMin = 1400.0;
  // Journal, direction : au-delà, les professeurs en colonne à gauche (300)
  // et la feuille du jour à droite, assez large pour rester une feuille.
  static const double journalDirectionSplitMin = 1260.0;
  // Présences, fiche mensuelle (largeur de l'onglet) : au-delà, les élèves en
  // colonne à gauche, la fiche du mois à droite.
  static const double studentMonthSplitMin = 1100.0;
  // Contrôle des frais (largeur reçue) : au-delà, l'aperçu d'un élève s'ancre
  // à droite du tableau, qui garde ses ~900 dp de disposition large.
  static const double feeControlDockedSheetMin = 1400.0;
  // Récapitulatif d'une inscription (largeur de sa carte) : au-delà, l'élève
  // et sa famille à gauche, sa scolarité et ses frais à droite.
  static const double enrollmentSummaryTwoColumnMin = 900.0;
  // Fiche d'un agent en consultation (fenêtre, page plein écran) : au-delà,
  // la fiche entière sur deux colonnes, sans assistant à étapes.
  static const double staffFileViewMin = expanded;
  // Contrôle des frais — table à 7 colonnes (identité + attendu/payé/reste +
  // statut). En deçà, les colonnes de montant seraient tronquées par l'ellipse :
  // on replie sur 3 colonnes et Attendu/Payé passent en ligne secondaire.
  //
  // Mesuré sur le CONTENU, déjà amputé de la barre latérale (280) et des
  // marges (48) : à 1024 il fallait un écran de 1352 px, et un poste en 1280
  // restait en disposition étroite (952 dp de contenu). À 900, une colonne de
  // montant garde ~130 dp — « 1 250 000,00 FC » tient sans ellipse (mesuré
  // par `fee_control_data_table_wide_test`).
  static const double feeControlTableWideMin = 900.0;
  // Caisse boutique : panier en colonne à côté du catalogue. Mesuré sur la
  // zone de la page (sous la barre latérale) : 420 de panier + 24 d'écart
  // laissent au catalogue au moins ~530 dp, deux tuiles d'articles.
  static const double boutiqueSideCartMin = sideBySideMin;
  // Fiche d'une dépense : le fil passe en colonne quand le corps de la
  // modale dépasse ~820 dp — 340 de fil, 480 de faits au moins.
  static const double expenseDetailTwoColMin = 820.0;
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

  /// Largeur d'une ligne élève à partir de laquelle un geste de plus
  /// (« Désactiver ») tient à côté du nom et de « Transférer ».
  static const double classesMemberTileExtraActionMin = 360.0;

  /// Largeur d'écran sous laquelle les actions de dossier de la barre sombre
  /// passent en icône seule (Désactiver, Fiche d'inscription, Modifier).
  static const double enrollmentJourneyActionLabelsMin = 1024.0;

  // Tableau de bord des présences (Disciplines) — la paire 1fr/1fr
  // (Jour/Top classes) passe en colonne sous ce seuil.
  static const double attendanceOverviewTwoColMin = 880.0;

  /// Saisie de notes, mode Focus, en paysage : le pavé passe à côté de la
  /// note au lieu d'en dessous — sans quoi une tablette de 600 dp de haut
  /// défilait à chaque élève.
  static const double saisieFocusSideBySideMin = 720.0;
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
