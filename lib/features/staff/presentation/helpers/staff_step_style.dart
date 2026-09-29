import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// La couleur et l'icône de chacune des quatre étapes de la page agent : le
/// filet des blocs, leur médaillon.
class StaffStepStyle {
  final Color color;
  final IconData icon;

  const StaffStepStyle._(this.color, this.icon);

  static const List<StaffStepStyle> _steps = [
    StaffStepStyle._(AppColors.bleuArdoise, Icons.person_outline),
    StaffStepStyle._(AppColors.vertSavane, Icons.place_outlined),
    StaffStepStyle._(AppColors.terreCuite, Icons.work_outline),
    StaffStepStyle._(AppColors.staffStepDocuments, Icons.school_outlined),
  ];

  static StaffStepStyle of(int step) => _steps[step.clamp(0, 3)];
}
