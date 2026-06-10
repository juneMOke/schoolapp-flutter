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
  // Modale d'encaissement (spec MODALE-12 : centrée, largeur 560).
  static const facturationCreatePaymentModalMaxWidth = 560.0;
  // Sur-couche d'encaissement 2 étapes (Confirmation → Résultat) : largeur 440.
  static const facturationCollectModalMaxWidth = 440.0;
  // Largeur min d'un champ de la recherche bi-mode (auto-fit 3→1 colonne).
  static const searchFieldMinWidth = 170.0;
  static const searchFieldGap = 10.0;
  // Largeur min d'une cellule du bandeau KPI stats (garde-fou anti-écrasement).
  static const financeStatsKpiCellMinWidth = 220.0;
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

  // Connexion — panneau formulaire (spec §01).
  // Split : largeur = clamp(400, 38% conteneur, 460). Empilé : max 400.
  static const loginFormPanelMin = 400.0;
  static const loginFormPanelMax = 460.0;
  static const loginFormPanelRatio = 0.38;
  static const loginFormStackedMax = 400.0;

  // Attendance page tokens
  static const attendanceStudentAvatarSize = 30.0;
  static const attendanceResultsPanelMinHeight = 360.0;
  static const attendanceResultsPanelMaxHeight = 620.0;
  static const attendanceCounterValueFontSize = 16.0;
  static const attendanceCycleFieldWidth = 170.0;
  static const attendanceLevelFieldWidth = 170.0;
  static const attendanceClassFieldWidth = 210.0;
  static const attendanceDateFieldWidth = 190.0;
  static const attendanceCounterColumnWidth = 72.0;

  // Enrollment stats dashboard tokens
  static const enrollmentStatsKpiCardHeight = 104.0;
  static const enrollmentStatsKpiCardMinWidth = 148.0;
  static const enrollmentStatsKpiCardMobileWidth = 168.0;
  static const enrollmentStatsChartSectionHeight = 220.0;
  static const enrollmentStatsChartRadius = 12.0;
  static const enrollmentStatsChartBorderRadius = 8.0;
  static const enrollmentStatsPeriodFilterHeight = 38.0;
  static const enrollmentStatsDonutCenterRadius = 48.0;
  static const enrollmentStatsHeaderTitleFontSize = 20.0;

  // Enrollment results bar tokens
  static const enrollmentResultsBarGap = 10.0;
  static const enrollmentResultsFilterChipHPadding = 10.0;
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

  // Finance stats dashboard tokens
  static const financeStatsHeaderTitleFontSize = 20.0;
  static const financeStatsKpiPrimaryValueFontSize = 32.0;
  static const financeStatsKpiSecondaryValueFontSize = 22.0;
  static const financeStatsKpiDividerHeight = 64.0;
  static const financeStatsFeeTypeProgressHeight = 8.0;
}
