import 'package:school_app_flutter/core/theme/tokens/app_colors.dart' as tokens;

class AppColors {
  AppColors._();

  static const bleuArdoise = tokens.AppColors.bleuArdoise;
  static const bleuProfond = tokens.AppColors.bleuProfond;
  static const terreCuite = tokens.AppColors.terreCuite;
  static const orDoux = tokens.AppColors.orDoux;
  static const vertSavane = tokens.AppColors.vertSavane;
  static const blancCasse = tokens.AppColors.blancCasse;
  static const papier = tokens.AppColors.papier;
  static const noirChaud = tokens.AppColors.noirChaud;
  static const info = tokens.AppColors.info;
  static const error = tokens.AppColors.error;
  static const textMuted = tokens.AppColors.textMuted;
  static const textOnDark = tokens.AppColors.textOnDark;
  static const surface = tokens.AppColors.surface;
  static const surfaceAlt = tokens.AppColors.surfaceAlt;
  static const surfaceRaised = tokens.AppColors.surfaceRaised;
  static const surfaceDark = tokens.AppColors.surfaceDark;
  static const borderStrong = tokens.AppColors.borderStrong;
  static const stateHover = tokens.AppColors.stateHover;
  static const statePressed = tokens.AppColors.statePressed;
  static const stateFocus = tokens.AppColors.stateFocus;
  static const stateDisabled = tokens.AppColors.stateDisabled;
  static const fabBackground = tokens.AppColors.fabBackground;

  // Base palette
  static const indigo = tokens.AppColors.bleuArdoise;
  static const indigoDark = tokens.AppColors.bleuProfond;
  static const green = tokens.AppColors.vertSavane;
  static const red = tokens.AppColors.error;
  static const background = tokens.AppColors.surface;
  static const textPrimary = tokens.AppColors.textPrimary;
  static const textSecondary = tokens.AppColors.textSecondary;
  static const border = tokens.AppColors.border;

  // Page background palette (gradient + halos — partagé entre tous les modules)
  static const pageBackgroundGradientStart = tokens.AppColors.surface;
  static const pageBackgroundGradientEnd = tokens.AppColors.surfaceCool;
  static const pageBackgroundHaloBlue = tokens.AppColors.bleuArdoise;
  static const pageBackgroundHaloTerracotta = tokens.AppColors.terreCuite;

  // Finance detail palette
  static const financeDetailCard = tokens.AppColors.financeDetailCard;
  static const financeDetailMutedSurface =
      tokens.AppColors.financeDetailMutedSurface;
  static const financeDetailAccent = tokens.AppColors.financeDetailAccent;
  static const financeDetailAccentSoft =
      tokens.AppColors.financeDetailAccentSoft;
  static const financeDetailSecondaryAccent =
      tokens.AppColors.financeDetailSecondaryAccent;
  static const financeDetailSecondaryAccentSoft =
      tokens.AppColors.financeDetailSecondaryAccentSoft;
  static const financeDetailSuccessSoft =
      tokens.AppColors.financeDetailSuccessSoft;
  static const financeDetailWarningSoft =
      tokens.AppColors.financeDetailWarningSoft;
  static const financeDetailDangerSoft =
      tokens.AppColors.financeDetailDangerSoft;
  static const financeDetailShadow = tokens.AppColors.financeDetailShadow;

  // Finance — Paiements (violet)
  static const financeDetailPaymentsAccent =
      tokens.AppColors.financeDetailPaymentsAccent;
  static const financeDetailPaymentsAccentLight =
      tokens.AppColors.financeDetailPaymentsAccentLight;
  static const financeDetailPaymentsAccentSoft =
      tokens.AppColors.financeDetailPaymentsAccentSoft;

  // Finance — Charges (émeraude) — utilisé pour la liste des charges
  static const financeDetailChargesAccent =
      tokens.AppColors.financeDetailChargesAccent;
  static const financeDetailChargesAccentSoft =
      tokens.AppColors.financeDetailChargesAccentSoft;

  // Finance — Info charge (orange ardoise) — utilisé pour la page de détail d'une charge
  static const financeDetailChargeInfoAccent =
      tokens.AppColors.financeDetailChargeInfoAccent;
  static const financeDetailChargeInfoAccentSoft =
      tokens.AppColors.financeDetailChargeInfoAccentSoft;
  static const financeDetailChargeInfoSurface =
      tokens.AppColors.financeDetailChargeInfoSurface;
  static const financeDetailChargeInfoSurfaceAlt =
      tokens.AppColors.financeDetailChargeInfoSurfaceAlt;

  // Finance — Méta badge Cycle (ambre)
  static const financeDetailAmber = tokens.AppColors.financeDetailAmber;
  static const financeDetailAmberSoft = tokens.AppColors.financeDetailAmberSoft;

  // Finance — Méta badge Niveau (teal)
  static const financeDetailTeal = tokens.AppColors.financeDetailTeal;
  static const financeDetailTealSoft = tokens.AppColors.financeDetailTealSoft;

  // Finance detail section tones
  static const financeDetailStudentSurface =
      tokens.AppColors.financeDetailStudentSurface;
  static const financeDetailStudentSurfaceAlt =
      tokens.AppColors.financeDetailStudentSurfaceAlt;
  static const financeDetailInfoSurface =
      tokens.AppColors.financeDetailInfoSurface;
  static const financeDetailInfoSurfaceAlt =
      tokens.AppColors.financeDetailInfoSurfaceAlt;
  static const financeDetailPaymentsSurface =
      tokens.AppColors.financeDetailPaymentsSurface;
  static const financeDetailPaymentsSurfaceAlt =
      tokens.AppColors.financeDetailPaymentsSurfaceAlt;
  static const financeDetailChargesSurface =
      tokens.AppColors.financeDetailChargesSurface;
  static const financeDetailChargesSurfaceAlt =
      tokens.AppColors.financeDetailChargesSurfaceAlt;
  static const financeDetailStudentTitle =
      tokens.AppColors.financeDetailStudentTitle;
  static const financeDetailInfoTitle = tokens.AppColors.financeDetailInfoTitle;
  static const financeDetailPaymentsTitle =
      tokens.AppColors.financeDetailPaymentsTitle;
  static const financeDetailChargesTitle =
      tokens.AppColors.financeDetailChargesTitle;

  static const financeDetailChargeRowPaid =
      tokens.AppColors.financeDetailChargeRowPaid;
  static const financeDetailChargeRowPartial =
      tokens.AppColors.financeDetailChargeRowPartial;
  static const financeDetailChargeRowDue =
      tokens.AppColors.financeDetailChargeRowDue;

  // Statut de frais — spec Facturation §20
  static const feeStatusPaid = tokens.AppColors.feeStatusPaid;
  static const feeStatusPaidSoft = tokens.AppColors.feeStatusPaidSoft;
  static const feeStatusPaidBorder = tokens.AppColors.feeStatusPaidBorder;
  static const feeStatusPartial = tokens.AppColors.feeStatusPartial;
  static const feeStatusPartialSoft = tokens.AppColors.feeStatusPartialSoft;
  static const feeStatusPartialBorder = tokens.AppColors.feeStatusPartialBorder;
  static const feeStatusDue = tokens.AppColors.feeStatusDue;
  static const feeStatusDueSoft = tokens.AppColors.feeStatusDueSoft;
  static const feeStatusDueBorder = tokens.AppColors.feeStatusDueBorder;
  static const billingHelpSurface = tokens.AppColors.billingHelpSurface;
  static const billingHelpBorder = tokens.AppColors.billingHelpBorder;
  static const billingPaymentMedallionSoft =
      tokens.AppColors.billingPaymentMedallionSoft;

  // Disciplinary detail palette
  static const disciplinaryDetailCard = tokens.AppColors.disciplinaryDetailCard;
  static const disciplinaryDetailAccent =
      tokens.AppColors.disciplinaryDetailAccent;
  static const disciplinaryDetailAccentSoft =
      tokens.AppColors.disciplinaryDetailAccentSoft;
  static const disciplinaryDetailTeal = tokens.AppColors.disciplinaryDetailTeal;
  static const disciplinaryDetailTealSoft =
      tokens.AppColors.disciplinaryDetailTealSoft;
  static const disciplinaryDetailInfoSurface =
      tokens.AppColors.disciplinaryDetailInfoSurface;
  static const disciplinaryDetailShadow =
      tokens.AppColors.disciplinaryDetailShadow;

  // Classes organisation palette
  static const classesHeroGradientStart =
      tokens.AppColors.classesHeroGradientStart;
  static const classesHeroGradientEnd = tokens.AppColors.classesHeroGradientEnd;
  static const classesSectionSurface = tokens.AppColors.classesSectionSurface;
  static const classesInfoBannerSurface =
      tokens.AppColors.classesInfoBannerSurface;
  static const classesInfoBannerBorder =
      tokens.AppColors.classesInfoBannerBorder;
  static const classesClassroomSurface =
      tokens.AppColors.classesClassroomSurface;
  static const classesMemberSurface = tokens.AppColors.classesMemberSurface;
  static const classesChipGirlsBg = tokens.AppColors.classesChipGirlsBg;
  static const classesChipGirlsFg = tokens.AppColors.classesChipGirlsFg;
  static const classesChipBoysBg = tokens.AppColors.classesChipBoysBg;
  static const classesChipBoysFg = tokens.AppColors.classesChipBoysFg;
  static const classesChipTotalBg = tokens.AppColors.classesChipTotalBg;
  static const classesChipTotalFg = tokens.AppColors.classesChipTotalFg;
  static const classesFocusRing = tokens.AppColors.classesFocusRing;
  static const classesDisabledBg = tokens.AppColors.classesDisabledBg;
  static const classesDisabledFg = tokens.AppColors.classesDisabledFg;

  // Relationship colours
  static const relationshipFather = tokens.AppColors.relationshipFather;
  static const relationshipMother = tokens.AppColors.relationshipMother;
  static const relationshipGuardian = tokens.AppColors.relationshipGuardian;
  static const relationshipUncle = tokens.AppColors.relationshipUncle;
  static const relationshipAunt = tokens.AppColors.relationshipAunt;
  static const relationshipGrandparent =
      tokens.AppColors.relationshipGrandparent;
  static const relationshipOther = tokens.AppColors.relationshipOther;

  static const success = tokens.AppColors.success;
  static const warning = tokens.AppColors.warning;
  static const muted = tokens.AppColors.textMuted;
  static const danger = tokens.AppColors.error;

  // Enrollment stats dashboard palette
  static const enrollmentStatsAccent = tokens.AppColors.enrollmentStatsAccent;
  static const enrollmentStatsAccentSoft =
      tokens.AppColors.enrollmentStatsAccentSoft;
  static const enrollmentStatsFirst = tokens.AppColors.enrollmentStatsFirst;
  static const enrollmentStatsFirstSoft =
      tokens.AppColors.enrollmentStatsFirstSoft;
  static const enrollmentStatsRe = tokens.AppColors.enrollmentStatsRe;
  static const enrollmentStatsReSoft = tokens.AppColors.enrollmentStatsReSoft;
  static const enrollmentStatsPre = tokens.AppColors.enrollmentStatsPre;
  static const enrollmentStatsPreSoft = tokens.AppColors.enrollmentStatsPreSoft;
  static const enrollmentStatsInProgress =
      tokens.AppColors.enrollmentStatsInProgress;
  static const enrollmentStatsInProgressSoft =
      tokens.AppColors.enrollmentStatsInProgressSoft;
  static const enrollmentStatsMale = tokens.AppColors.enrollmentStatsMale;
  static const enrollmentStatsFemale = tokens.AppColors.enrollmentStatsFemale;
  static const enrollmentStatsCardSurface =
      tokens.AppColors.enrollmentStatsCardSurface;
  static const enrollmentStatsChartGrid =
      tokens.AppColors.enrollmentStatsChartGrid;
}
