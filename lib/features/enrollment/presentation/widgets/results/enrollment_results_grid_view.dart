import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
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
    return EteeloGridView(
      itemCount: enrollments.length,
      itemBuilder: (context, index) {
        final enrollment = enrollments[index];
        return EnrollmentResultCard(
          enrollment: enrollment,
          onTap: () => onViewRequested(enrollment),
        );
      },
    );
  }
}
