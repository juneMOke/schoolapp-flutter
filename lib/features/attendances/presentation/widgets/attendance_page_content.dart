import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_models.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_results_section.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_search_form.dart';

class AttendancePageContent extends StatelessWidget {
  final List<AttendanceCycleOption> options;
  final AttendanceSearchRequest? lastRequest;
  final ValueChanged<AttendanceSearchRequest> onSearch;
  final VoidCallback onRetry;

  const AttendancePageContent({
    super.key,
    required this.options,
    required this.lastRequest,
    required this.onSearch,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.entrance,
      curve: AppMotion.outCurve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * AppDimensions.spacingL),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: AnimatedSwitcher(
        duration: AppMotion.standard,
        switchInCurve: AppMotion.outCurve,
        switchOutCurve: AppMotion.inCurve,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AttendanceSearchForm(options: options, onSearch: onSearch),
            const SizedBox(height: AppDimensions.spacingM),
            AttendanceResultsSection(
              key: ValueKey<String>(
                'attendance-results-${lastRequest != null}',
              ),
              lastRequest: lastRequest,
              onRetry: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
