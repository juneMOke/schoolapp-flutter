import 'package:school_app_flutter/core/constants/app_breakpoints.dart';

class EnrollmentListingLayout {
  final double width;
  final bool isShellCompact;
  final bool forceGridResults;

  const EnrollmentListingLayout({
    required this.width,
    required this.isShellCompact,
    required this.forceGridResults,
  });

  factory EnrollmentListingLayout.fromWidth(double width) {
    return EnrollmentListingLayout(
      width: width,
      isShellCompact: width < AppBreakpoints.enrollmentShellCompactMax,
      forceGridResults: width < AppBreakpoints.enrollmentTableGridSwitchMax,
    );
  }
}
