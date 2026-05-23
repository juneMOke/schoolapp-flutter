import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/attendance_page_helpers.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_models.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_results_section.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_search_form.dart';

class AttendancePageContent extends StatelessWidget {
  final List<AttendanceCycleOption> options;
  final AttendanceSearchRequest? lastRequest;
  final ValueChanged<AttendanceSearchRequest> onSearch;
  final VoidCallback onExportPressed;
  final VoidCallback onRetry;

  const AttendancePageContent({
    super.key,
    required this.options,
    required this.lastRequest,
    required this.onSearch,
    required this.onExportPressed,
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
            BlocBuilder<AttendanceBloc, AttendanceState>(
              buildWhen: AttendancePageHelpers.buildWhenSearchFormChanges,
              builder: (context, state) {
                return AttendanceSearchForm(
                  options: options,
                  isSearching:
                      state.fetchStatus == AttendanceStatus.loading ||
                      state.saveStatus == AttendanceStatus.loading,
                  onSearch: onSearch,
                );
              },
            ),
            const SizedBox(height: AppDimensions.spacingM),
            AttendanceResultsSection(
              key: ValueKey<String>(
                'attendance-results-${lastRequest != null}',
              ),
              lastRequest: lastRequest,
              onExportPressed: onExportPressed,
              onRetry: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
