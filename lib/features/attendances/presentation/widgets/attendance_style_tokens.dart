import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

class AttendanceStyleTokens {
  const AttendanceStyleTokens._();

  static const double recordNameFontSize = 17;
  static const double recordHelperFontSize = 11;
  static const double badgeFontSize = 12;

  static const EdgeInsets cardPaddingCompact = EdgeInsets.symmetric(
    horizontal: AppDimensions.spacingM,
    vertical: AppDimensions.spacingS,
  );
  static const EdgeInsets cardPaddingDefault = EdgeInsets.all(
    AppDimensions.spacingM,
  );

  static const Size saveButtonMinSize = Size(176, AppDimensions.minTouchTarget);
  static const Size exportButtonMinSize = Size(
    152,
    AppDimensions.minTouchTarget,
  );

  static const bool tooltipPreferBelow = false;

  static Color cardBackground({
    required bool isPresent,
    required bool hasError,
  }) {
    if (hasError) {
      return AppColors.financeDetailDangerSoft.withValues(alpha: 0.28);
    }

    if (isPresent) {
      return AppColors.financeDetailSuccessSoft.withValues(alpha: 0.18);
    }

    return AppColors.financeDetailMutedSurface;
  }
}
