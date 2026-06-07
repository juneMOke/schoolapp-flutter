class AppBreakpoints {
  const AppBreakpoints._();

  // Global responsive breakpoints (single source of truth).
  static const double detailCompactMax = 760.0;
  static const double homeMobileMax = 768.0;
  static const double navigationCompactMax = 1024.0;
  static const double enrollmentShellCompactMax = navigationCompactMax;
  static const double dataTableCardsMax = 600.0;
  static const double fabExtendedMinWidth = dataTableCardsMax;
  static const double tableFooterStackMax = 560.0;
  static const double dataTablePhoneMax = 390.0;
  static const double enrollmentTableGridSwitchMax = dataTableCardsMax;
  static const double authWideMin = 800.0;
  static const double formMediumMin = 860.0;
  static const double formWideMin = 1280.0;

  // Facturation — seuils responsive dédiés (spec §00 : occupation de l'espace).
  // Bascule des tuiles KPI détail en colonne sous cette largeur (très petits
  // écrans), pour que le montant tienne en pleine largeur sans réduction.
  static const double kpiStripStackMax = dataTablePhoneMax; // 390
  // Au-delà : la page détail élargit son contenu et juxtapose Paiements | Frais.
  static const double financeDetailTwoColMin = navigationCompactMax; // 1024
  // Dashboard stats : juxtapose Évolution | Répartition par frais au-delà.
  static const double financeStatsTwoColMin = 1100.0;
  // KPI band stats : 2 colonnes / 4 colonnes (valeurs conservées à l'identique).
  static const double financeStatsKpiTwoColMin = 480.0;
  static const double financeStatsKpiFourColMin = 780.0;
  // Section par type de frais : 2 colonnes / 3 colonnes (valeurs conservées).
  static const double financeStatsFeeTypeTwoColMin = 640.0;
  static const double financeStatsFeeTypeThreeColMin = 980.0;
  // Pied de modale : en deçà, les deux boutons s'empilent (sinon Row).
  static const double financeModalFooterRowMin = 360.0;
}
