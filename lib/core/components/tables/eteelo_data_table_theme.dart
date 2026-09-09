import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Tokens visuels centralises pour toutes les tables de l'application.
class EteeloDataTableTheme {
  const EteeloDataTableTheme._();

  // Container
  static const Color containerBackground = AppColors.surfaceRaised;
  static const Color containerBorder = AppColors.border;
  static const bool showContainerShadow = false;

  // Table root
  static const Color tableBackground = AppColors.surfaceRaised;

  // Header
  static const double headerHorizontalPadding = 18;
  static const double headerVerticalPaddingComfortable = 12;
  static const double headerVerticalPaddingCompact = 8;
  static const double leadingSlotWidth = 36;
  static const double trailingSlotWidth = 44;
  static const double slotGap = AppDimensions.spacingS;
  static const Color headerBackground = AppColors.surfaceRaised;
  static final TextStyle headerLabelStyle = AppTextStyles.tableHeader.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.9,
  );
  static const Color headerSortActiveColor = AppColors.bleuArdoise;
  static const Color headerSortInactiveColor = AppColors.textSecondary;
  static const Color focusRingColor = AppColors.bleuArdoise;
  static const double focusRingWidth = 2;
  static const double focusRingOffset = 2;

  // Rows
  static const double rowHeightComfortable = 58;
  static const double rowHeightCompact = 48;
  static const double rowHorizontalPadding = AppDimensions.spacingM;
  static const Color rowEvenBackground = AppColors.surfaceRaised;
  static const Color rowOddBackground = AppColors.surfaceRaised;
  static const Color rowHoverBackground = AppColors.stateHover;
  static const Color rowHoverLeadingBorder = AppColors.bleuArdoise;
  static const double rowLeadingBorderWidth = 3;

  // Cells
  // ## Chiffres tabulaires dans les trois variantes
  //
  // C'est la raison d'être d'une table : une colonne de montants, de dates ou
  // de numéros de pièce se **parcourt du regard**, et des chiffres de largeurs
  // différentes décalent chaque ligne d'un cran imprévisible. Le « 1 » d'une
  // fonte proportionnelle est deux fois plus étroit que le « 8 » : 1 111 et
  // 8 888 n'ont pas la même longueur, et l'œil qui compare deux lignes doit
  // relire au lieu de balayer.
  //
  // Sur les trois variantes et non sur la seule colonne de montants : une date
  // et un numéro de reçu forment aussi des colonnes, et une table dont deux
  // colonnes s'alignent et trois autres non se lit plus mal que si aucune ne
  // s'alignait. Le texte sans chiffre n'est pas affecté.
  static final TextStyle cellRegularStyle = AppTextStyles.caption.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    fontFeatures: AppTextStyles.tabularFigures,
  );
  static final TextStyle cellStrongStyle = AppTextStyles.caption.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFeatures: AppTextStyles.tabularFigures,
  );
  static final TextStyle cellMonoStyle = AppTextStyles.codeMuted.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
    fontFeatures: AppTextStyles.tabularFigures,
  );

  // Footer
  static const double footerHeight = 44;
  static const double footerHorizontalPadding = AppDimensions.spacingL;
  static const Color footerBackground = AppColors.surfaceRaised;
  static const Color footerChipBackground = AppColors.stateHover;
  static const Color footerChipTextColor = AppColors.bleuArdoise;
  static const double footerChipRadius = 20;

  // States
  static const double stateIconContainerSize = 80;
  static const double stateIconSize = 40;
  static const EdgeInsets statePadding = EdgeInsets.symmetric(
    vertical: 64,
    horizontal: 32,
  );

  // Borders / separators
  static const double separatorThickness = 1;
  static const Color separatorColor = AppColors.border;

  // Motion
  static const Duration rowHoverDuration = AppMotion.micro;
  static const Duration interactionDuration = AppMotion.fast;
}
