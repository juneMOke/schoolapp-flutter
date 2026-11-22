import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';

/// Les teintes du Recouvrement v2, prises **sur la maquette vivante**
/// (`ui_kits/app/Recouvrement.jsx`, `RecFraisBar`, `REC_STATUTS`, `RecMini`) et
/// ramenées aux jetons de l'app.
///
/// Une seule source pour les deux pages : la barre « Quels frais analyser ? »
/// et les couleurs de situation sont identiques au tableau de bord et au
/// contrôle.
class RecouvrementV2Tones {
  const RecouvrementV2Tones._();

  /// Fond de la barre de périmètre : blanc vers terre cuite très pâle
  /// (`linear-gradient(115deg, #FFFFFF 0%, #FBF3EC 100%)`).
  static const perimeterGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.surfaceRaised, AppColors.terreCuiteSoft],
  );

  /// Bord de la barre : la terre cuite à 38 % dans la bordure
  /// (`color-mix(in srgb, var(--terre-cuite) 38%, var(--border))`).
  static Color get perimeterBorder =>
      ColorMix.tint(AppColors.border, AppColors.terreCuite, 38);

  /// Ombre portée de la barre (`0 14px 30px -22px rgba(14,45,66,.65)`).
  static final perimeterShadow = [
    BoxShadow(
      color: AppColors.bleuProfond.withValues(alpha: 0.65),
      blurRadius: 30,
      offset: const Offset(0, 14),
      spreadRadius: -22,
    ),
  ];

  /// Bord du champ des frais : terre cuite à 55 %.
  static Color get feeFieldBorder =>
      ColorMix.tint(AppColors.border, AppColors.terreCuite, 55);

  /// Les couleurs des pastilles de frais, dans l'ordre de l'école. La maquette
  /// en donne quatre ; la cinquième et les suivantes reprennent la série.
  ///
  /// ⚠️ Écart assumé : le troisième ton de la maquette (`#D9A24E`, l'or doux)
  /// porte du texte blanc à 2,1:1 ; l'ambre d'encre le remplace, lisible.
  static const feePalette = <Color>[
    AppColors.bleuArdoise,
    AppColors.vertSavane,
    AppColors.ambreInk,
    AppColors.info,
  ];

  static Color feeColor(int index) => feePalette[index % feePalette.length];

  /// Couleur forte et fond pâle d'une situation (`REC_STATUTS`).
  static (Color, Color) situation(StudentChargeStatus? status) =>
      switch (status) {
        StudentChargeStatus.due => (
          AppColors.feeStatusDue,
          AppColors.feeStatusDueSoft,
        ),
        StudentChargeStatus.partial => (
          AppColors.feeStatusPartial,
          AppColors.feeStatusPartialSoft,
        ),
        StudentChargeStatus.paid => (
          AppColors.feeStatusPaid,
          AppColors.feeStatusPaidSoft,
        ),
        null => (AppColors.bleuArdoise, AppColors.bleuArdoiseSoft),
      };
}
