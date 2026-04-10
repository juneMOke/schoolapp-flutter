import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';

class EnrollmentTheme {
  static const Color pendingColor = Color(0xFFFB8C00);
  static const Color validatedColor = Color(0xFF4CAF50);
  static const Color rejectedColor = Color(0xFFF44336);

  static BoxDecoration get searchCardDecoration => BoxDecoration(
    color: AppTheme.surfaceColor,
    borderRadius: BorderRadius.circular(EnrollmentConstants.cardRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration get dataTableDecoration => BoxDecoration(
    color: AppTheme.surfaceColor,
    borderRadius: BorderRadius.circular(EnrollmentConstants.cardRadius),
    border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
  );
}
