import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/enrollment_theme.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';

extension EnrollmentStatusColorX on EnrollmentStatus {
  Color get badgeColor {
    return switch (this) {
      EnrollmentStatus.preRegistered => EnrollmentTheme.pendingColor,
      EnrollmentStatus.inProgress => Colors.blue,
      EnrollmentStatus.adminCompleted => Colors.indigo,
      EnrollmentStatus.financialCompleted => Colors.teal,
      EnrollmentStatus.completed => EnrollmentTheme.validatedColor,
      EnrollmentStatus.cancelled => EnrollmentTheme.rejectedColor,
      EnrollmentStatus.validated => EnrollmentTheme.validatedColor,
      EnrollmentStatus.rejected => EnrollmentTheme.rejectedColor,
      EnrollmentStatus.pending => EnrollmentTheme.pendingColor,
    };
  }

  Color get tableBackgroundColor {
    return switch (this) {
      EnrollmentStatus.preRegistered => const Color(0xFFEFF6FF),
      EnrollmentStatus.inProgress => const Color(0xFFFFFBEB),
      EnrollmentStatus.adminCompleted => const Color(0xFFF5F3FF),
      EnrollmentStatus.financialCompleted => const Color(0xFFECFDF5),
      EnrollmentStatus.completed => const Color(0xFFD1FAE5),
      EnrollmentStatus.validated => const Color(0xFFDCFCE7),
      EnrollmentStatus.cancelled => const Color(0xFFFEF2F2),
      EnrollmentStatus.rejected => const Color(0xFFFFEDE8),
      EnrollmentStatus.pending => const Color(0xFFF3F4F6),
    };
  }

  Color get tableForegroundColor {
    return switch (this) {
      EnrollmentStatus.preRegistered => const Color(0xFF1D4ED8),
      EnrollmentStatus.inProgress => const Color(0xFFB45309),
      EnrollmentStatus.adminCompleted => const Color(0xFF6D28D9),
      EnrollmentStatus.financialCompleted => const Color(0xFF0D9488),
      EnrollmentStatus.completed => const Color(0xFF059669),
      EnrollmentStatus.validated => const Color(0xFF16A34A),
      EnrollmentStatus.cancelled => const Color(0xFFDC2626),
      EnrollmentStatus.rejected => const Color(0xFFEA580C),
      EnrollmentStatus.pending => const Color(0xFF6B7280),
    };
  }
}
