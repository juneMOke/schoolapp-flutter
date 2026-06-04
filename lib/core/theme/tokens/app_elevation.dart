import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

class AppElevation {
  AppElevation._();

  static const List<BoxShadow> shadowKpi = [
    BoxShadow(color: Color(0x0A2C2A26), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> shadowCard = [
    BoxShadow(color: Color(0x0D2C2A26), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> shadowRaised = [
    BoxShadow(color: Color(0x142C2A26), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> shadowPop = [
    BoxShadow(color: Color(0x260E2D42), blurRadius: 32, offset: Offset(0, 12)),
  ];

  static BoxDecoration get surface1 => const BoxDecoration(
    color: AppColors.surfaceAlt,
    borderRadius: AppRadius.brMd,
  );

  static BoxDecoration get surface2 => BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.brMd,
    border: Border.all(color: AppColors.border),
    boxShadow: shadowKpi,
  );

  static BoxDecoration get surface3 => BoxDecoration(
    color: AppColors.surfaceRaised,
    borderRadius: AppRadius.brMd,
    border: Border.all(color: AppColors.border),
    boxShadow: shadowCard,
  );
}
