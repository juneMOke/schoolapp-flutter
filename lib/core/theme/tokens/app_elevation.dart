import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

class AppElevation {
  AppElevation._();

  static BoxDecoration get surface1 => const BoxDecoration(
	color: AppColors.surfaceAlt,
	borderRadius: AppRadius.brMd,
  );

  static BoxDecoration get surface2 => BoxDecoration(
	color: AppColors.surface,
	borderRadius: AppRadius.brMd,
	border: Border.all(color: AppColors.border),
  );

  static BoxDecoration get surface3 => BoxDecoration(
	color: AppColors.surfaceRaised,
	borderRadius: AppRadius.brMd,
	border: Border.all(color: AppColors.border),
  );
}
