import 'package:school_app_flutter/core/constants/app_breakpoints.dart';

class AppDimensions {
  static const sidebarWidth = 280.0;
  static const sidebarCollapsedWidth = 84.0;
  // Aligné sur AppTheme.topBarHeight (source unique de la hauteur de barre).
  static const topBarHeight = 68.0;
  static const pagePadding = 24.0;
  static const cardRadius = 20.0;
  static const spacingXS = 4.0;
  static const spacingS = 8.0;
  static const spacingM = 16.0;
  static const spacingL = 24.0;
  static const spacingXL = 32.0;

  static const sectionCardRadius = 18.0;
  static const detailCardPadding = 20.0;
  static const detailSectionSpacing = 20.0;
  static const detailHeaderIconSize = 24.0;
  static const detailMiniIconSize = 16.0;
  static const detailHeroAvatarSize = 64.0;
  static const detailBackButtonWidth = 220.0;
  static const detailContentMaxWidth = 1180.0;
  // Largeur de lecture plus resserrée pour la page de facturation (spec §00 :
  // contenu plafonné à 880 dp), centrée et responsive.
  static const facturationContentMaxWidth = 880.0;
  // Largeur fixe des modales de facturation (spec §00 : centrées, défilables).
  static const facturationModalMaxWidth = 520.0;
  // Sur-couche d'encaissement 2 étapes (Confirmation → Résultat) : largeur 440.
  static const facturationCollectModalMaxWidth = 440.0;
  // Popin « Choisir un payeur » (encaissement). Ses tokens sont à elle et non
  // empruntés à la recherche de tuteur : les deux popins se ressemblent
  // aujourd'hui, mais ajuster l'une ne doit pas déplacer l'autre.
  static const facturationPayerSearchModalMaxWidth = 560.0;

  /// Largeur d'un critère d'identité de la recherche de payeur (Nom,
  /// Post-nom, Prénom), posés dans un `Wrap`.
  static const facturationPayerSearchCriterionWidth = 200.0;
  static const facturationPayerSearchResultsMinHeight = 200.0;
  // Visionneuse de document — pièce scellée, rapport, registre, ticket : plus
  // large que les modales de saisie — une page A4 portrait doit rester lisible
  // sans zoom sur tablette paysage (1280×800 dp de référence).
  static const documentViewerMaxWidth = 760.0;
  // Hauteur du gabarit de page pendant la préparation du document :
  // proportion A4 approchée à la largeur de la visionneuse.
  static const documentViewerSkeletonHeight = 420.0;
  // Largeur min d'un champ de la recherche bi-mode (auto-fit 3→1 colonne).
  static const searchFieldMinWidth = 170.0;
  static const searchFieldGap = 10.0;
  // Largeur max de la carte d'invitation « avant recherche » (centrée).
  static const searchInvitationMaxWidth = 620.0;
  static const detailTableMinWidth = 860.0;
  static const detailInfoItemWidth = 224.0;
  static const detailTableLabelColumnWidth = 72.0;

  // Eteelo FAB tokens
  static const fabHeight = 56.0;
  static const fabPaddingStart = 18.0;
  static const fabPaddingEnd = 22.0;
  static const fabIconSize = 22.0;
  static const fabLabelGap = 9.0;
  // Décalage du FAB par rapport au bord (endFloat = 16 par défaut).
  static const fabEdgeOffset = 28.0;
  // Hauteur à réserver sous le contenu d'une page qui porte un FAB flottant :
  // sinon le FAB survole les derniers dp du contenu — typiquement la barre de
  // pagination, posée à droite du pied de tableau, sous le FAB au pixel près.
  static const fabScrollClearance = fabEdgeOffset + fabHeight + spacingS;

  // Pagination tokens
  static const paginationButtonSize = 32.0;
  static const paginationIconSize = 16.0;
  static const paginationGap = 6.0;
  static const paginationButtonRadius = 8.0;
  static const paginationTapTarget = 44.0;
  static const paginationIndicatorHPadding = 10.0;

  // Page background decorative tokens (halos + filigrane — partagé entre tous les modules)
  static const pageHaloBlueAlign = 0.72; // Alignment.x pour halo bleu
  static const pageHaloBlueAlignY = -1.16; // Alignment.y pour halo bleu
  static const pageHaloBlueRatio = 1100 / 460; // scaleX de l'ellipse
  static const pageHaloBlueOpacity = 0.08;

  static const pageHaloTerraAlign = -1.12; // Alignment.x pour halo terre-cuite
  static const pageHaloTerraAlignY = 1.24; // Alignment.y pour halo terre-cuite
  static const pageHaloTerraRatio = 900 / 520;
  static const pageHaloTerraOpacity = 0.07;

  static const pageHaloRadius = 0.9; // fraction du rayon du gradient radial

  // Filigrane Kuba
  static const kubaTileSize = 60.0;
  static const kubaOpacity = 0.07;

  // Finance detail elevation/responsive tokens
  static const financeDetailCardShadowBlur = 20.0;
  static const financeDetailCardShadowOffsetY = 10.0;
  static const detailCompactBreakpoint = AppBreakpoints.detailCompactMax;

  // Classes organisation responsive tokens
  static const classesOrganisationCompactFieldWidth = 260.0;
  static const classesOrganisationShadowBlur = 14.0;
  static const classesOrganisationShadowOffsetY = 8.0;
  static const classesDistributionResultModalMaxWidth = 460.0;
  static const classesReassignModalMaxWidth = 480.0;
  static const classesMemberTileMinWidth = 280.0;
  static const minTouchTarget = 48.0;

  /// Sélecteur d'imprimante thermique du ticket provisoire. Étroit à dessein :
  /// il ne porte qu'un nom et une adresse MAC par ligne, et s'ouvre par-dessus
  /// la modale d'encaissement (440) — le déborder le ferait lire comme un
  /// nouvel écran plutôt que comme un choix.
  static const ticketPrinterPickerWidth = 360.0;

  /// Case du nombre d'exemplaires, entre (−) et (+) : assez large pour deux
  /// chiffres sans que les boutons ne bougent quand la valeur change.
  static const ticketCopiesValueWidth = 32.0;

  /// Icône d'une ligne de détail des modales Facturation — même chasse que les
  /// lignes clé/valeur au-dessus desquelles elle s'aligne.
  static const financeRowIconSize = 18.0;

  // Popin "Rechercher un parent" (étape Tuteurs de l'inscription).
  static const guardianSearchModalMaxWidth = 560.0;

  /// Largeur d'un critère d'identité de la recherche de parent (Nom,
  /// Post-nom, Prénom), posés dans un `Wrap`.
  static const guardianSearchCriterionWidth = 200.0;
  static const guardianSearchResultsMinHeight = 200.0;

  // Connexion — panneau formulaire (spec §01).
  // Split : largeur = clamp(400, 38% conteneur, 460). Empilé : max 400.
  static const loginFormPanelMin = 400.0;
  static const loginFormPanelMax = 460.0;
  static const loginFormPanelRatio = 0.38;
  static const loginFormStackedMax = 400.0;

  // Onglet Discipline — carte de cas & frise de statut
  static const disciplinaryCardAccentWidth = 4.0;
  static const disciplinaryStepperDotSize = 22.0;
  static const disciplinaryStepperConnectorWidth = 18.0;
  static const disciplinaryStepperConnectorHeight = 2.0;
  static const disciplinaryStepperIconSize = 12.0;

  // Onglet Discipline — chips, pastilles & modale (carte + création)
  static const disciplinaryChipPaddingH = 10.0;
  static const disciplinaryChipPaddingV = 4.0;
  static const disciplinarySanctionChipPaddingV = 5.0;
  static const disciplinaryStatusPillPaddingH = 12.0;
  static const disciplinaryStatusPillPaddingV = 6.0;
  static const disciplinaryChipIconSize = 13.0;
  static const disciplinaryStatusPillIconSize = 15.0;
  static const disciplinaryCreateDialogMaxWidth = 500.0;
  static const disciplinaryCreateSubmitSpinnerSize = 18.0;
  // Tints alpha récurrents des chips/pastilles (fond + bordure).
  static const disciplinaryTintAlpha = 0.12;
  static const disciplinaryTintBorderAlpha = 0.25;
  static const disciplinarySanctionTintAlpha = 0.10;

  // Onglet Presence — synthese d'assiduite
  static const presenceMedallionSize = 30.0;
  static const presenceMedallionRadius = 9.0;
  static const presenceDistributionBarHeight = 8.0;
  static const presenceRowAccentBarWidth = 4.0;
  static const presenceRowAccentBarHeight = 30.0;
  static const presencePerfectMedallionSize = 64.0;
  static const presencePerfectIconSize = 30.0;

  // Enrollment stats dashboard tokens
  static const enrollmentStatsKpiCardHeight = 104.0;
  static const enrollmentStatsKpiCardMinWidth = 148.0;
  static const enrollmentStatsChartSectionHeight = 220.0;
  static const enrollmentStatsChartRadius = 12.0;
  static const enrollmentStatsChartBorderRadius = 8.0;

  // Géométrie des barres verticales (CycleBarChart).
  //
  // La largeur d'une barre est une **part du pas**, pas une valeur absolue :
  // c'est le rapport largeur/pas qui fait qu'une série se lit comme un rythme
  // plutôt que comme une rangée de traits. La spec le fixe à 46/86 sur un
  // tracé de 480 (barres à x = 60/146/232/318/404).
  static const enrollmentStatsChartBarWidthRatio = 0.53;
  static const enrollmentStatsChartBarMinWidth = 6.0;
  static const enrollmentStatsChartBarMaxWidth = 46.0;

  /// Largeur réservée à l'axe des ordonnées, à défalquer du tracé pour
  /// calculer le pas.
  static const enrollmentStatsChartLeftAxisWidth = 36.0;

  /// Intervalles de grille — une ligne de plus que d'intervalles.
  static const enrollmentStatsChartGridDivisions = 4;

  /// Le rythme des inscriptions suit la spec : radius 6, 3 lignes de grille.
  static const enrollmentStatsChartPaceBorderRadius = 6.0;
  static const enrollmentStatsChartPaceGridDivisions = 2;

  /// Pastille d'icône en tête d'une carte de section (EteeloStatsCard),
  /// calquée sur celle d'EteeloKpiCard.
  static const statsCardIconBadgeRadius = 8.0;
  static const statsCardIconSize = 16.0;
  static const enrollmentStatsChartBottomTitleHeight = 28.0;
  static const enrollmentStatsChartVerticalLabelMaxExtent = 84.0;
  static const enrollmentStatsPeriodFilterHeight = 38.0;
  static const enrollmentStatsDonutCenterRadius = 48.0;
  static const enrollmentStatsDonutLegendRowHeight = 42.0;
  static const enrollmentStatsLevelDonutMinHeight = 300.0;
  static const enrollmentStatsDonutMaxHeight = 360.0;
  static const enrollmentStatsHeaderTitleFontSize = 20.0;

  // Tableau de bord des inscriptions — pavés pleins et cartes teintées
  // (spec couleurs §03 et §04). 1 px CSS = 1 dp.
  static const insPaveRadius = 16.0;
  static const insPavePaddingH = 20.0;
  static const insPavePaddingTop = 18.0;
  static const insPavePaddingBottom = 16.0;
  static const insPaveHaloSize = 170.0;
  static const insPaveHaloTop = -70.0;
  static const insPaveHaloRight = -50.0;
  static const insPaveMedallionSize = 26.0;
  static const insPaveMedallionRadius = 8.0;
  static const insPaveMedallionIconSize = 15.0;
  static const insPaveHeaderGap = 9.0;
  static const insPaveLabelLetterSpacing = 0.66; // ~.06em sur 11 sp
  static const insPaveLabelFontSize = 11.0;
  static const insPaveValueFontSize = 34.0;
  static const insPaveSublineFontSize = 12.0;
  static const insPaveShadowBlur = 26.0;
  static const insPaveShadowOffsetY = 10.0;

  /// Plancher de hauteur d'un pavé plein. Plus haut que celui d'une carte
  /// claire : la valeur y est en 34 sp au lieu de 24, et le libellé passe
  /// au-dessus d'elle au lieu d'en dessous.
  static const insPaveMinHeight = 140.0;

  /// Médaillon d'en-tête d'une carte de section **teintée** — plus grand que
  /// la pastille de 16 dp des cartes blanches ([statsCardIconSize]), qu'il ne
  /// remplace pas : les deux coexistent selon que la carte porte un ton.
  static const insSectionRadius = 16.0;
  static const insSectionMedallionSize = 34.0;
  static const insSectionMedallionRadius = 11.0;
  static const insSectionMedallionIconSize = 18.0;
  static const insSectionFiletHeight = 1.0;
  static const insSectionFiletFadeStop = 0.62;

  /// Rayon du cadre d'une table **teintée** (spec Première inscription §04).
  /// Une table non teintée n'a pas de cadre, donc pas de rayon : c'est le
  /// bandeau d'en-tête coloré qui rend l'arrondi nécessaire.
  static const listeTableRadius = 10.0;

  /// Rayon de la barre de résultats — la surface qui **nomme l'état** de la
  /// recherche, et la seule teintée en permanence quel que soit cet état.
  static const listeBarRadius = 14.0;

  /// Filet d'or en tête du bandeau d'effectif — la seule surface dégradée de
  /// l'écran. Il s'efface au même arrêt que le filet de section.
  static const insBannerFiletHeight = 3.0;

  // Enrollment results bar tokens
  static const enrollmentResultsBarGap = 10.0;
  static const enrollmentResultsFilterChipHPadding = 10.0;

  // Recouvrement — pastilles du sélecteur de frais (spec §2). La pastille fait
  // 38 dp ; la rangée qui la porte atteint les 44 dp de cible tactile avec son
  // interligne.
  static const recouvrementFeeChipHeight = 38.0;
  static const recouvrementFeeChipRadius = 999.0;
  static const recouvrementFeeChipIconSize = 15.0;
  static const recouvrementScopeFieldWidth = 230.0;
  // Barres du taux par frais (spec §4) : hauteur 20, radius 5.
  static const recouvrementRateBarHeight = 20.0;
  static const recouvrementRateBarRadius = 5.0;

  // « Où en est chaque niveau » : barre tricolore d'un cycle (10) et, plus
  // fine, de ses niveaux (6). Un liseré de 2 sépare les parts, pour qu'elles se
  // distinguent aussi sans la couleur.
  static const recouvrementTriBarHeight = 10.0;
  static const recouvrementTriBarDenseHeight = 6.0;
  static const recouvrementTriBarRadius = 5.0;
  static const recouvrementTriBarGap = 2.0;
  static const recouvrementCountDot = 8.0;
  static const recouvrementChevronSize = 20.0;
  // Les niveaux se décalent du chevron de leur cycle et de son interligne :
  // leurs noms s'alignent sur celui du cycle.
  static const recouvrementLevelIndent = 24.0;
  static const recouvrementViewButtonSize = 36.0;
  static const recouvrementViewIconSize = 18.0;

  // Simulation de renvoi (spec §6).
  static const recouvrementCriterionFieldWidth = 260.0;
  static const recouvrementThresholdFieldWidth = 190.0;
  static const recouvrementWarningMaxWidth = 300.0;
  static const recouvrementKeptBarHeight = 8.0;

  // Lectures & alertes (spec §8) : médaillon 34, cartes 260 → 380.
  static const recouvrementInsightMedallion = 34.0;
  static const recouvrementInsightMinWidth = 260.0;
  static const recouvrementInsightMaxWidth = 380.0;

  // Aperçu nominatif d'un groupe visé (spec §7).
  static const recouvrementCallListMaxWidth = 720.0;
  static const recouvrementCallListMaxHeight = 620.0;
  static const recouvrementCallListSpinner = 16.0;

  // Aperçu nominatif d'un élève — la fiche qui désagrège ses frais.
  static const recouvrementStudentSheetMaxWidth = 560.0;
  static const recouvrementStudentSheetMinPinned = 300.0;
  static const recouvrementFeeLineBarHeight = 7.0;

  static const enrollmentResultsFilterChipVPadding = 4.0;
  static const enrollmentResultsFilterChipIconSize = 13.0;
  static const enrollmentResultsFilterChipCloseIconSize = 12.0;
  static const enrollmentResultsSortSelectWidth = 168.0;
  static const enrollmentResultsViewToggleHeight = 38.0;
  static const enrollmentResultsViewToggleItemHeight = 30.0;

  // Grid + result card tokens
  // Largeur mini d'une carte (équivaut au `min` de `minmax(300, 1fr)`) : les
  // colonnes sont calculées pour ne jamais descendre sous cette largeur.
  static const gridMinItemWidth = 300.0;
  // Largeur mini d'un champ de filtre (équivaut au `min` de `minmax(190, 1fr)`).
  static const filterGridMinItemWidth = 190.0;
  static const resultCardAccentWidth = 5.0;
  static const resultCardBodyPaddingH = 18.0;
  static const resultCardBodyPaddingV = 16.0;
  static const resultCardHoverTranslateY = -2.0;
  static const chipPaddingH = 10.0;
  static const chipPaddingV = 4.0;
  static const chipIconSize = 12.0;

  /// Picto d'état de synchro d'une ligne de listing (SyncStateIcon) : assez
  /// grand pour rester lisible sans libellé, assez discret pour ne pas
  /// concurrencer la pastille de statut métier voisine.
  static const syncStateIconSize = 16.0;

  // Finance stats dashboard tokens
  static const financeStatsHeaderTitleFontSize = 20.0;
  static const financeStatsFeeTypeProgressHeight = 8.0;

  // Disciplines — tableau de bord des presences (attendance overview)
  static const kpiCardHeightWithSubline = 128.0;

  /// Hauteur ajoutée par chaque valeur au-delà de la première, sur une carte KPI
  /// qui empile plusieurs devises. Deux montants ne se somment pas : ils
  /// s'écrivent l'un sous l'autre, et la carte grandit d'autant.
  static const kpiCardExtraValueHeight = 22.0;
  static const attendanceOverviewTrendMinRate = 70.0;
  static const attendanceOverviewTrendMaxRate = 100.0;
  static const attendanceOverviewTargetRate = 95.0;
  static const attendanceOverviewDonutCenterRadius = 46.0;
  static const attendanceOverviewDonutRingThickness = 28.0;
  static const attendanceOverviewSplitBarHeight = 16.0;
  static const attendanceOverviewClassSplitBarHeight = 9.0;
  static const attendanceOverviewTopBarHeight = 8.0;
  static const attendanceOverviewRankBadgeSize = 24.0;
  // Seuil d'alerte : un taux d'absence non justifiee >= 4 % passe en rouge gras.
  static const attendanceOverviewUnjustifiedAlertThreshold = 4.0;

  // Coquille fiche élève (Liste disciplines ▸ détail) — DossierTabs & panneau
  static const dossierTabsPadding = 6.0;
  static const dossierTabRadius = 13.0;
  static const dossierTabMinHeight = 44.0;
  static const dossierMedallionSize = 40.0;
  static const dossierMedallionRadius = 12.0;
  static const dossierBadgeMinSize = 19.0;
  // Hauteur du dégradé soft → surface du panneau d'onglet.
  static const dossierPanelTintHeight = 260.0;

  // Boutique — sélecteur de niveau d'une ligne de panier walk-in. Il partage
  // la rangée avec la puce bénéficiaire et le compteur : assez large pour un
  // libellé de niveau, assez court pour que la rangée ne se replie pas.
  static const boutiqueCartLevelSelectorWidth = 168.0;

  // ── Tableau de bord Inscriptions (refonte) ───────────────────────────────
  // « 1 px CSS = 1 dp Flutter » : les valeurs ci-dessous reprennent la spec du
  // design system telle quelle. Préfixées `enrollmentDashboard` pour ne pas se
  // confondre avec les tokens `enrollmentStats` de l'écran précédent, qui
  // vivent encore le temps de la migration.

  /// Bandeau d'effectif — le seul repère qui subsiste à l'état vide.
  static const enrollmentDashboardBannerPaddingV = 22.0;
  static const enrollmentDashboardBannerPaddingH = 26.0;
  static const enrollmentDashboardBannerGap = 18.0;

  /// Le total en 64 dp : le seul chiffre de l'écran à cette taille. Il répond à
  /// « combien », la première des trois lectures.
  static const enrollmentDashboardHeadcountFontSize = 64.0;
  static const enrollmentDashboardBannerIconSize = 15.0;

  /// Interlettrage du sur-titre en majuscules. La spec l'exprime en `.09em` sur
  /// un label-small (11 dp) — soit ~1 dp, la valeur portée ici puisque Flutter
  /// compte l'interlettrage en dp et non en cadratins.
  static const enrollmentDashboardOvertitleLetterSpacing = 1.0;

  /// Onglets de fenêtre. 44 dp est une **cible tactile**, pas une hauteur
  /// décorative : « le choix de la période est l'action la plus fréquente de
  /// l'écran, il ne doit jamais être confondu avec un filtre secondaire ».
  static const enrollmentDashboardTabMinHeight = 44.0;

  /// Trait de l'indicateur qui remplace l'icône d'un bouton d'export pendant
  /// que le serveur compose — fin, pour tenir dans la case d'une icône de
  /// 16 dp.
  static const enrollmentDashboardExportSpinnerStroke = 2.0;
  static const enrollmentDashboardTabsPadding = 6.0;
  static const enrollmentDashboardTabsRadius = 14.0;
  static const enrollmentDashboardTabRadius = 10.0;
  static const enrollmentDashboardTabIconSize = 16.0;
  static const enrollmentDashboardTabGap = 8.0;
  static const enrollmentDashboardTabPaddingH = 18.0;

  /// Champs Du/Au de la fenêtre personnalisée.
  static const enrollmentDashboardDateFieldWidth = 150.0;

  /// Barres. Le rayon 999 fait la pilule quelle que soit la hauteur.
  static const enrollmentDashboardSplitBarHeight = 16.0;
  static const enrollmentDashboardRowBarHeight = 9.0;
  static const enrollmentDashboardRowLabelWidth = 132.0;
  static const enrollmentDashboardPillRadius = 999.0;

  /// Rythme : barres à coins doux.
  static const enrollmentDashboardPaceBarRadius = 6.0;

  /// Plancher du domaine haut du graphique de rythme.
  ///
  /// Le défaut du socle est 10 — invisible en finance (montants en centimes),
  /// dévastateur ici : une école qui inscrit 1 à 3 élèves par jour verrait
  /// toutes ses barres écrasées contre l'axe, tous les jours. À 4, une journée
  /// à 1 inscription occupe encore le quart de la hauteur.
  static const enrollmentDashboardPaceMinTop = 4.0;

  /// Avatar d'une ligne de la liste nominative des inscrits.
  static const enrollmentDashboardDayAvatarSize = 30.0;
  static const enrollmentDashboardTypePillIconSize = 13.0;

  /// Lectures & alertes : cartes qui s'enroulent, jamais rendues « pour remplir
  /// la ligne » — chacune a sa condition.
  static const enrollmentDashboardInsightMinWidth = 250.0;
  static const enrollmentDashboardInsightBadgeSize = 28.0;

  // ── Dépenses (spec « Dépenses ▸ Frais de fonctionnement ») ────────────────

  /// Écart entre une icône (ou un libellé) et son voisin sur une même ligne.
  static const expenseInlineGap = 6.0;

  /// Rayon des médaillons de 34 dp, des notes et des encarts d'alerte.
  static const expenseIconBoxRadius = 10.0;

  /// Rayon des encarts de lecture et du bandeau de montant de la fiche.
  static const expenseInsetRadius = 12.0;

  /// Icône d'un médaillon de 34 dp (en-tête de section, encart de lecture).
  static const expenseMedallionIconSize = 18.0;

  /// Filet d'accent à gauche d'un encart de lecture.
  static const expenseAccentBorderWidth = 3.0;

  /// Respiration verticale d'une note et d'une ligne de référence de la fiche.
  static const expenseNotePaddingV = 10.0;

  /// Pastille de légende de la répartition.
  static const expenseLegendDotSize = 10.0;
  static const expenseLegendDotRadius = 3.0;

  /// Médaillon d'un type : 26 dp en fiche et en puce, 22 dp dans une ligne.
  static const expenseTypeTagSize = 26.0;
  static const expenseTypeTagSizeSmall = 22.0;
  static const expenseTypeTagRadius = 7.0;
  static const expenseTypeTagIconSize = 14.0;
  static const expenseTypeTagIconSizeSmall = 12.0;

  /// Puce de filtre par type : 34 dp de haut, cible portée à 44 par la marge.
  static const expenseChipHeight = 34.0;
  static const expenseChipRadius = 999.0;
  static const expenseChipIconSize = 14.0;

  /// Pas à pas de période : flèches 36 × 36, libellé à largeur fixe pour que
  /// les flèches ne bougent pas d'un pas à l'autre.
  static const expensePeriodArrowSize = 36.0;
  static const expensePeriodArrowRadius = 10.0;
  static const expensePeriodArrowIconSize = 17.0;
  static const expensePeriodLabelWidth = 188.0;

  /// Boutons d'action d'une ligne du registre (bascule, duplication).
  static const expenseRowActionSize = 34.0;
  static const expenseRowActionRadius = 9.0;
  static const expenseRowActionIconSize = 15.0;

  /// Sous cette largeur, une ligne du registre passe sur deux rangées.
  static const expenseRowWideMinWidth = 820.0;

  /// Pastille de statut.
  static const expenseStatusIconSize = 14.0;
  static const expenseStatusIconSizeSmall = 12.0;

  /// Modales : formulaire 600, fiche 560.
  static const expenseFormDialogMaxWidth = 600.0;
  static const expenseDetailDialogMaxWidth = 560.0;
  static const expenseDetailMedallionSize = 44.0;
  static const expenseDetailMedallionIconSize = 22.0;
  static const expenseDetailLabelWidth = 150.0;

  /// Chaîne de validation : trois jalons accolés en tête de fiche.
  static const expenseChainPaddingV = 11.0;
  static const expenseChainPaddingH = 14.0;
  static const expenseChainIconSize = 15.0;

  /// Le jalon hors d'atteinte — « ne sera pas payée » — reste lisible mais
  /// visiblement éteint.
  static const expenseChainDimmedOpacity = 0.5;

  /// Panneau de refus : un motif tout prêt reste sur une ligne.
  static const expenseRefusalChipMaxWidth = 260.0;

  /// Fil de la demande : vignette d'acte et bulle de message.
  static const expenseThreadMedallionSize = 30.0;
  static const expenseThreadMedallionRadius = 9.0;
  static const expenseThreadMedallionIconSize = 15.0;
  static const expenseThreadBubbleRadius = 11.0;
  static const expenseThreadBubblePaddingH = 13.0;

  /// Tableau de bord : hauteur du graphique d'évolution et de l'anneau.
  static const expenseChartHeight = 190.0;
  static const expenseDonutHeight = 200.0;
  static const expenseInsightMinWidth = 260.0;
  static const expenseInsightMedallionSize = 34.0;

  /// Tableau de bord : répartition et top 5 côte à côte au-delà de cette
  /// largeur, empilés en dessous.
  static const expenseDashboardTwoColumnsMinWidth = 800.0;

  /// Formulaire : largeurs des champs d'une même rangée, qui passent en pile
  /// quand la modale se resserre.
  static const expenseFormTypeMinWidth = 240.0;
  static const expenseFormTypeMaxWidth = 360.0;
  static const expenseFormDateMinWidth = 180.0;
  static const expenseFormDateMaxWidth = 200.0;
  static const expenseFormAmountMaxWidth = 240.0;
  static const expenseFormFundingMinWidth = 200.0;
  static const expenseFormFundingMaxWidth = 280.0;

  // ── Ressources humaines — fichier du personnel ──
  /// Champ de recherche : il prend la place qui reste, jamais moins.
  static const searchToolbarMinWidth = 280.0;
  static const searchToolbarMaxWidth = 460.0;
  static const staffCategoryWidth = 220.0;

  /// Largeur plancher d'une carte d'agent dans la grille.
  static const staffCardMinWidth = 290.0;

  /// Hauteur d'une puce de filtre (zone de tap étendue à 44 par le padding).
  static const filterChipHeight = 40.0;

  /// Hauteur plancher d'une ligne du tableau.
  static const staffTableRowMinHeight = 60.0;

  /// Largeur plafond du formulaire de la page agent : au-delà, les lignes de
  /// champs s'étirent sans rien apporter.
  static const staffAgentBodyMaxWidth = 960.0;

  /// Largeur d'une tuile de statut dans le choix du contrat : trois tiennent
  /// sur une ligne de tablette, elles passent à la ligne en portrait.
  static const staffContractTileWidth = 240.0;

  /// Filet d'une tuile de statut : plus épais que le filet courant, pour que
  /// la tuile choisie se lise sans compter sur la couleur seule.
  static const staffContractTileBorderWidth = 1.5;
  static const staffContractTileIconSize = 18.0;

  // ── Ressources humaines — pointage du personnel (spec B, redlines) ──
  /// Largeur plancher d'une carte de la grille : autant de colonnes que
  /// possible, pour des cartes d'environ 220 à 262 dp, entièrement tactiles.
  static const presenceMarkCardMinWidth = 220.0;
  static const presenceMarkAvatarSize = 44.0;
  static const presenceMarkMedallionSize = 46.0;
  static const presenceMarkMedallionIconSize = 24.0;

  /// Bouton d'icône d'un pied de carte (effacer, réessayer).
  static const presenceMarkIconButtonSize = 36.0;

  /// Cible tactile standard du module : puces, flèches, segments.
  static const presenceMarkTapTarget = 44.0;
  static const presenceMarkSegmentHeight = 40.0;
  static const presenceMarkRingSize = 64.0;
  static const presenceMarkRingStroke = 7.0;
  static const presenceMarkBorderWidth = 2.0;
  static const presenceMarkAccentWidth = 4.0;

  /// La vue liste : largeur plancher avant défilement, et ses colonnes.
  static const presenceMarkListMinWidth = 900.0;
  static const presenceMarkColStatus = 262.0;
  static const presenceMarkColTimes = 168.0;
  static const presenceMarkColHours = 96.0;
  static const presenceMarkColAction = 40.0;

  /// Les modales du pointage.
  static const formDialogMaxWidth = 480.0;
  static const formDialogMaxHeight = 640.0;

  /// Fiche mensuelle : sélecteur d'agent et calendrier.
  static const presenceMarkPickerWidth = 340.0;
  static const presenceMarkPickerMaxHeight = 360.0;
  static const presenceMarkCalendarCellHeight = 56.0;

  /// Le récapitulatif : ses colonnes.
  static const staffAttendanceRecapColContract = 112.0;
  static const staffAttendanceRecapColCount = 96.0;
  static const staffAttendanceRecapColSync = 104.0;
  static const staffAttendanceRecapMinWidth = 820.0;

  /// Opacité de la grille d'un jour validé : lisible, visiblement figée.
  static const presenceMarkFrozenOpacity = 0.78;

  /// Au-delà, les quatre indicateurs de la fiche tiennent sur une ligne.
  static const presenceMarkKpiWideBreakpoint = 720.0;

  /// Part de la ligne du registre couverte par le voile de son statut.
  static const presenceMarkRowTintStop = 0.3;

  /// Opacité d'un jour à venir dans le calendrier de la fiche mensuelle.
  static const presenceMarkUpcomingOpacity = 0.4;

  // ── Présences des élèves (appel par classe) ──
  /// Le sélecteur de classe : une modale plus large que les modales de saisie,
  /// pour tenir les classes d'un niveau sur une ligne.
  static const classPickerDialogMaxWidth = 620.0;
  static const classPickerClassHeight = 48.0;
  static const classPickerClassMinWidth = 120.0;

  /// Le bouton de classe de l'en-tête et son médaillon.
  static const classPickerButtonHeight = 52.0;
  static const classPickerMedallionSize = 38.0;

  /// Le tableau du récapitulatif de l'appel : colonnes fixes, défilement
  /// horizontal sous sa largeur plancher.
  static const classRecapMinWidth = 760.0;
  static const classRecapColPresences = 150.0;
  static const classRecapColRate = 76.0;
  static const classRecapColLates = 104.0;
  static const classRecapColAbsences = 96.0;
  static const classRecapColSync = 120.0;
  static const classRecapRateBarWidth = 90.0;
  static const classRecapWatchDot = 8.0;

  // ── RH ▸ Paie ─────────────────────────────────────────────────────────────
  // Le livre défile horizontalement sous 920 dp ; les colonnes de montant sont
  // alignées à droite, en chiffres tabulaires.
  static const payrollLedgerMinWidth = 920.0;
  static const payrollColAmount = 100.0;
  static const payrollColSmallAmount = 80.0;
  static const payrollColAttendance = 88.0;
  static const payrollColPayout = 136.0;
  static const payrollAdvancesMinWidth = 880.0;
  static const payrollColDate = 104.0;
  static const payrollColSchedule = 150.0;
  static const payrollColStatus = 120.0;
  static const payrollHistoryMinWidth = 820.0;
  static const payrollColMonth = 150.0;
  static const payrollColCount = 72.0;

  /// La feuille du bulletin et son panneau latéral.
  static const payrollPayslipMaxWidth = 720.0;
  static const payrollPayslipPanelWidth = 270.0;
  static const payrollPayslipWideBreakpoint = 1000.0;

  /// Le filet or sous l'en-tête du bulletin.
  static const payrollPayslipRule = 3.0;
  static const payrollStepperButton = 40.0;
  static const payrollStepperValueWidth = 56.0;
  static const payrollCircuitDot = 30.0;
  static const payrollCircuitLink = 14.0;
  static const payrollModeTileHeight = 52.0;
  static const payrollProgressHeight = 8.0;

  // ── Photo de l'élève (spec « Photo de l'élève », 1 px = 1 dp) ────────────
  /// Le panneau de capture : largeur maximale, rayon, et en dessous de quelle
  /// largeur d'écran il passe en plein écran.
  static const photoPanelMaxWidth = 580.0;
  static const photoPanelRadius = 22.0;
  static const photoPanelFullscreenBelow = 600.0;
  static const photoViewfinderRadius = 14.0;
  static const photoShutter = 68.0;
  static const photoShutterRing = 4.0;
  static const photoDarkButton = 44.0;
  static const photoCloseButton = 40.0;
  static const photoCloseRadius = 12.0;
  static const photoGuideStroke = 2.5;

  /// La zone de recadrage carrée, et le retrait du cercle à l'intérieur.
  static const photoCropSide = 300.0;
  static const photoCropInset = 10.0;

  /// Envoi et confirmation : l'aperçu et la coche.
  static const photoSavingPreview = 150.0;
  static const photoSavedCheck = 38.0;

  /// L'emplacement de l'étape 1 : la colonne, le cercle et son anneau.
  static const photoSlotColumn = 148.0;
  static const photoSlotCircle = 128.0;
  static const photoSlotRing = 4.0;
  static const photoSlotReflowBelow = 552.0;
  static const photoSlotActionHeight = 40.0;
  static const photoSlotLinkHeight = 32.0;

  /// L'avatar modifiable de l'en-tête, son badge caméra et son contour.
  static const photoHeaderAvatar = 42.0;
  static const photoHeaderMenuWidth = 240.0;
  static const photoHeaderMenuItem = 44.0;

  /// La ligne photo du Résumé.
  static const photoRecapAvatar = 52.0;

  /// Séance photo : tuiles de classe, prise de vue, file.
  static const photoSessionTileMin = 190.0;
  static const photoSessionCheck = 22.0;
  static const photoSessionCoverageBar = 6.0;
  static const photoSessionProgressBar = 4.0;
  static const photoSessionShootMin = 520.0;
  static const photoSessionQueueMin = 300.0;
  static const photoSessionQueueMax = 400.0;
  static const photoSessionStackBelow = 840.0;
  static const photoSessionHeaderAvatar = 44.0;
  static const photoSessionQueueRow = 56.0;
  static const photoSessionQueueAvatar = 36.0;
  static const photoSessionCurrentRule = 4.0;
  static const photoSessionFlashPreview = 160.0;
  static const photoSessionSummaryMedallion = 72.0;
  static const photoSessionSummaryAvatar = 40.0;
  static const photoSessionClassMedallion = 46.0;
  static const photoSessionTileRadius = 14.0;
  static const photoSessionCountTile = 140.0;

  /// La hauteur que la file laisse à l'en-tête et aux marges : elle défile
  /// dans « 100 % de l'écran moins 260 ».
  static const photoSessionQueueReserve = 260.0;

  /// Le badge caméra de l'avatar d'en-tête : au moins 20 dp, sinon 42 % de
  /// l'avatar ; et l'écart du contour pointillé.
  static const photoHeaderBadgeMin = 20.0;
  static const photoHeaderBadgeRatio = 0.42;
  static const photoHeaderOutlineGap = 3.0;
  static const photoHeaderOutlineStroke = 2.0;
  static const photoHeaderBadgeBorder = 2.5;

  /// Les petites icônes de la photo (puces, liens, curseur) et le trait des
  /// bordures fines sur fond sombre.
  static const photoIconXs = 14.0;
  static const photoIconSm = 16.0;
  static const photoIconMd = 18.0;
  static const photoHairline = 1.5;
  static const photoFlashRing = 3.0;
  static const photoFilterRow = 44.0;

  /// L'écart entre « Prendre » et « Importer », et la marge horizontale de
  /// la ligne photo du Résumé.
  static const photoSlotActionGap = 6.0;
  static const photoRecapPaddingH = 14.0;

  /// L'avatar du bénéficiaire en boutique : la puce du panier, la liste de
  /// choix.
  static const boutiqueBeneficiaryChipAvatar = 22.0;
  static const boutiqueBeneficiaryListAvatar = 34.0;

  /// Le sujet d'une évaluation (spec Évaluation §4 bis, S2-S4) : numéro de
  /// ligne du programme et badge de question, boutons d'action d'une
  /// question, champ des points, bouton « Ajouter une question », barre du
  /// barème, champ « Autre » de la durée.
  static const sujetNumberBadge = 28.0;
  static const sujetIconAction = 32.0;
  static const sujetIconSize = 16.0;
  static const sujetPointsFieldWidth = 92.0;
  static const sujetAddQuestionHeight = 48.0;
  static const sujetBaremeBar = 6.0;
  static const sujetDureeOtherWidth = 120.0;
}
