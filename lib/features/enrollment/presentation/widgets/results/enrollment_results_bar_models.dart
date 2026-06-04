import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

class EnrollmentResultsSortOption {
  final String value;
  final String label;

  const EnrollmentResultsSortOption({required this.value, required this.label});
}

class EnrollmentResultsActiveFilter {
  final String id;
  final String label;
  final Color softColor;
  final Color color;
  final IconData? icon;
  final VoidCallback? onRemove;
  final String? removeSemanticLabel;

  const EnrollmentResultsActiveFilter({
    required this.id,
    required this.label,
    this.softColor = AppColors.surfaceAlt,
    this.color = AppColors.bleuArdoise,
    this.icon,
    this.onRemove,
    this.removeSemanticLabel,
  });
}
