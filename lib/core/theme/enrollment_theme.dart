import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';

class EnrollmentTheme {
  static const Color pendingColor = AppColors.warning;
  static const Color validatedColor = AppColors.success;
  static const Color rejectedColor = AppColors.error;

  static BoxDecoration get searchCardDecoration => AppElevation.surface1;

  static BoxDecoration get dataTableDecoration => AppElevation.surface2;
}
