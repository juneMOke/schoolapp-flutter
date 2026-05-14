import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_organisation_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_pending_distribution_card.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_split_results.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesOrganisationResultsSection extends StatelessWidget {
  final ClassesOrganisationCycleOption? selectedCycle;
  final ClassesOrganisationLevelOption? selectedLevel;
  final bool isDistributing;
  final VoidCallback onDistributionRequested;
  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;

  const ClassesOrganisationResultsSection({
    super.key,
    required this.selectedCycle,
    required this.selectedLevel,
    required this.isDistributing,
    required this.onDistributionRequested,
    required this.onTransferTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (selectedCycle == null) {
      return ClassesOrganisationEmptyStateCard(
        icon: Icons.account_tree_outlined,
        title: l10n.classesOrganisationSelectCycleAndLevelTitle,
        subtitle: l10n.classesOrganisationSelectCycleAndLevelSubtitle,
      );
    }

    if (selectedLevel == null) {
      return ClassesOrganisationEmptyStateCard(
        icon: Icons.school_outlined,
        title: l10n.classesOrganisationSelectLevelTitle,
        subtitle: l10n.classesOrganisationSelectLevelSubtitle(selectedCycle!.label),
      );
    }

    return BlocBuilder<ClassroomBloc, ClassroomState>(
      buildWhen: (previous, current) =>
          previous.distributionOverviewStatus != current.distributionOverviewStatus ||
          previous.distributionOverview != current.distributionOverview ||
          previous.distributionOverviewErrorType != current.distributionOverviewErrorType ||
          previous.reassignStatus != current.reassignStatus ||
          previous.reassigningMemberId != current.reassigningMemberId,
      builder: (context, classroomState) {
        if (!selectedLevel!.splitIntoClassrooms) {
          final plannedClassroomCount = selectedLevel!.classrooms.length;

          return ClassesOrganisationPendingDistributionCard(
            isDistributing: isDistributing,
            studentsToDistribute: classroomState.distributionOverview?.unassignedEnrollments.length ?? 0,
            plannedClassroomCount: plannedClassroomCount,
            onDistributionRequested: onDistributionRequested,
          );
        }

        return ClassesOrganisationSplitResults(
          selectedLevel: selectedLevel!,
          overviewStatus: classroomState.distributionOverviewStatus,
          overviewErrorType: classroomState.distributionOverviewErrorType,
          overview: classroomState.distributionOverview,
          isReassigning: classroomState.reassignStatus == ClassroomStatus.loading,
          reassigningMemberId: classroomState.reassigningMemberId,
          errorMessage: ClassesOrganisationPageHelpers.mapClassroomErrorToMessage(l10n, classroomState.distributionOverviewErrorType),
          onTransferTap: onTransferTap,
        );
      },
    );
  }
}

class ClassesOrganisationEmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ClassesOrganisationEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: ClassesOrganisationDashedBorderPainter(
        color: AppColors.borderStrong.withValues(alpha: 0.4),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        decoration: BoxDecoration(
          color: AppColors.papier,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.bleuArdoise.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: AppDimensions.spacingM, color: AppColors.bleuArdoise),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              title,
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              subtitle,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ClassesOrganisationDashedBorderPainter extends CustomPainter {
  final Color color;

  const ClassesOrganisationDashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const borderRadius = Radius.circular(AppDimensions.cardRadius);
    final rect = Offset.zero & size;
    final rRect = RRect.fromRectAndRadius(rect.deflate(0.5), borderRadius);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()..addRRect(rRect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + 8).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ClassesOrganisationDashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
