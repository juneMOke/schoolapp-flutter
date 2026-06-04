import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_result_card.dart';

class EnrollmentResultsGridView extends StatelessWidget {
  final List<EnrollmentSummary> enrollments;
  final ValueChanged<EnrollmentSummary> onViewRequested;

  const EnrollmentResultsGridView({
    super.key,
    required this.enrollments,
    required this.onViewRequested,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateColumns(constraints.maxWidth);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.85,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.lg,
          ),
          itemCount: enrollments.length,
          padding: EdgeInsets.all(AppSpacing.lg),
          itemBuilder: (context, index) {
            final enrollment = enrollments[index];
            return EnrollmentResultCard(
              enrollment: enrollment,
              onTap: () => onViewRequested(enrollment),
              onViewDetails: () => onViewRequested(enrollment),
            );
          },
        );
      },
    );
  }

  int _calculateColumns(double width) {
    // Mobile: 1 col, Tablet: 2 cols, Desktop: 3+ cols
    if (width < 600) return 1;
    if (width < 900) return 2;
    return 3;
  }
}
