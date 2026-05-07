import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Groupe 1 - couleurs de marque
  static const bleuArdoise = Color(0xFF1B4D6B);
  static const bleuProfond = Color(0xFF0E2D42);
  static const terreCuite = Color(0xFFB85C2C);
  static const orDoux = Color(0xFFD9A24E);
  static const vertSavane = Color(0xFF3D6B4A);
  static const blancCasse = Color(0xFFFAFAF7);
  static const papier = Color(0xFFF1EDE2);
  static const noirChaud = Color(0xFF2C2A26);

  // Groupe 2 - couleurs semantiques
  static const success = vertSavane;
  static const warning = Color(0xFFD68910);
  static const error = Color(0xFFC0392B);
  static const info = Color(0xFF2E6E8E);

  // Groupe 3 - couleurs fonctionnelles
  static const textPrimary = noirChaud;
  static const textSecondary = Color(0xFF5C5852);
  static const textMuted = Color(0xFF8C8478);
  static const textOnDark = blancCasse;
  static const surface = blancCasse;
  static const surfaceAlt = papier;
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const surfaceDark = bleuProfond;
  static const border = Color(0xFFE3DFD2);
  static const borderStrong = Color(0xFFC9C3B0);
  static const stateHover = Color(0x0F1B4D6B);
  static const statePressed = Color(0x1F1B4D6B);
  static const stateFocus = Color(0x331B4D6B);
  static const stateDisabled = border;

  // Legacy palettes centralisees dans la source unique de tokens.
  static const pageBackgroundGradientStart = surface;
  static const pageBackgroundGradientMiddle = surfaceAlt;
  static const pageBackgroundGradientEnd = surface;
  static const pageBackgroundAccent = bleuArdoise;

  // Finance detail palette
  static const financeDetailCard = surfaceRaised;
  static const financeDetailMutedSurface = Color(0xFFF5F8FF);
  static const financeDetailAccent = Color(0xFF1A73E8);
  static const financeDetailAccentSoft = Color(0xFFE8F0FE);
  static const financeDetailSecondaryAccent = Color(0xFF3F51B5);
  static const financeDetailSecondaryAccentSoft = Color(0xFFEAF0FF);
  static const financeDetailSuccessSoft = Color(0xFFDCFCE7);
  static const financeDetailWarningSoft = Color(0xFFEAF0FF);
  static const financeDetailDangerSoft = Color(0xFFFEE2E2);
  static const financeDetailShadow = Color(0x14243352);

  // Finance - Paiements
  static const financeDetailPaymentsAccent = Color(0xFF6366F1);
  static const financeDetailPaymentsAccentLight = Color(0xFF818CF8);
  static const financeDetailPaymentsAccentSoft = Color(0xFFEDE9FE);

  // Finance - Charges
  static const financeDetailChargesAccent = Color(0xFF10B981);
  static const financeDetailChargesAccentSoft = Color(0xFFD1FAE5);

  // Finance - Info charge
  static const financeDetailChargeInfoAccent = Color(0xFFEA580C);
  static const financeDetailChargeInfoAccentSoft = Color(0xFFFFF7ED);
  static const financeDetailChargeInfoSurface = Color(0xFFFFFAF5);
  static const financeDetailChargeInfoSurfaceAlt = surfaceRaised;

  // Finance - Meta
  static const financeDetailAmber = Color(0xFFD97706);
  static const financeDetailAmberSoft = Color(0xFFFEF3C7);
  static const financeDetailTeal = Color(0xFF0891B2);
  static const financeDetailTealSoft = Color(0xFFE0F2FE);

  // Finance detail section tones
  static const financeDetailStudentSurface = Color(0xFFF7FCF8);
  static const financeDetailStudentSurfaceAlt = surfaceRaised;
  static const financeDetailInfoSurface = Color(0xFFF6F9FF);
  static const financeDetailInfoSurfaceAlt = surfaceRaised;
  static const financeDetailPaymentsSurface = Color(0xFFF5F3FF);
  static const financeDetailPaymentsSurfaceAlt = surfaceRaised;
  static const financeDetailChargesSurface = Color(0xFFF0FDF9);
  static const financeDetailChargesSurfaceAlt = surfaceRaised;
  static const financeDetailStudentTitle = Color(0xFF2E7D32);
  static const financeDetailInfoTitle = Color(0xFF1A73E8);
  static const financeDetailPaymentsTitle = Color(0xFF3F51B5);
  static const financeDetailChargesTitle = Color(0xFF2E7D32);
  static const financeDetailChargeRowPaid = Color(0xFFF1FAF2);
  static const financeDetailChargeRowPartial = Color(0xFFFFF7F0);
  static const financeDetailChargeRowDue = Color(0xFFFFF1F3);

  // Disciplinary detail palette
  static const disciplinaryDetailCard = surfaceRaised;
  static const disciplinaryDetailAccent = Color(0xFFDC2626);
  static const disciplinaryDetailAccentSoft = Color(0xFFFEE2E2);
  static const disciplinaryDetailTeal = Color(0xFF0891B2);
  static const disciplinaryDetailTealSoft = Color(0xFFE0F2FE);
  static const disciplinaryDetailInfoSurface = Color(0xFFF8F1F6);
  static const disciplinaryDetailShadow = Color(0x14243352);

  // Classes organisation palette
  static const classesHeroGradientStart = Color(0xFFEAF2FF);
  static const classesHeroGradientEnd = Color(0xFFF2F8FF);
  static const classesSectionSurface = Color(0xFFF9FBFF);
  static const classesInfoBannerSurface = Color(0xFFEEF4FF);
  static const classesInfoBannerBorder = Color(0xFFD7E4FF);
  static const classesClassroomSurface = Color(0xFFF7FAFF);
  static const classesMemberSurface = Color(0xFFF1F6FF);
  static const classesChipGirlsBg = Color(0xFFFCE7F3);
  static const classesChipGirlsFg = Color(0xFF9D174D);
  static const classesChipBoysBg = Color(0xFFE0ECFF);
  static const classesChipBoysFg = Color(0xFF1D4ED8);
  static const classesChipTotalBg = Color(0xFFE8F5E9);
  static const classesChipTotalFg = Color(0xFF1B5E20);
  static const classesFocusRing = Color(0xFF1A73E8);
  static const classesDisabledBg = Color(0xFFE5E7EB);
  static const classesDisabledFg = Color(0xFF6B7280);
}
