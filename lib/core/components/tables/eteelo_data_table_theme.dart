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
  static const double headerHeight = 46;
  static const double headerHorizontalPadding = AppDimensions.spacingM;
  static const double leadingSlotWidth = 36;
  static const double trailingSlotWidth = 32;
  static const double slotGap = AppDimensions.spacingS;
  static const Gradient headerGradient = LinearGradient(
    colors: [AppColors.surfaceRaised, AppColors.surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static final TextStyle headerLabelStyle = AppTextStyles.tableHeader.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 0.9,
  );
  static const Color headerSortActiveColor = AppColors.bleuArdoise;
  static const Color headerSortInactiveColor = AppColors.textMuted;

  // Rows
  static const double rowHeight = 58;
  static const double rowHorizontalPadding = AppDimensions.spacingM;
  static const Color rowEvenBackground = AppColors.surfaceRaised;
  static const Color rowOddBackground = AppColors.surfaceAlt;
  static const Color rowHoverBackground = AppColors.stateHover;
  static const Color rowHoverLeadingBorder = AppColors.bleuArdoise;
  static const double rowLeadingBorderWidth = 3;

  // Cells
  static final TextStyle cellRegularStyle = AppTextStyles.caption.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static final TextStyle cellStrongStyle = AppTextStyles.caption.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static final TextStyle cellMonoStyle = AppTextStyles.codeMuted.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
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
