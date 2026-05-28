import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/level_distribution_overview.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_classroom_card.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_common_widgets.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_unassigned_members_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesOrganisationSplitResults extends StatelessWidget {
  final ClassesOrganisationLevelOption selectedLevel;
  final ClassroomStatus overviewStatus;
  final ClassroomErrorType overviewErrorType;
  final LevelDistributionOverview? overview;
  final bool isReassigning;
  final String reassigningMemberId;
  final String? errorMessage;
  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;

  const ClassesOrganisationSplitResults({
    super.key,
    required this.selectedLevel,
    required this.overviewStatus,
    required this.overviewErrorType,
    required this.overview,
    required this.isReassigning,
    required this.reassigningMemberId,
    required this.errorMessage,
    required this.onTransferTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (overviewStatus == ClassroomStatus.loading ||
        overviewStatus == ClassroomStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (overviewStatus == ClassroomStatus.failure) {
      return ClassesOrganisationEmptyCard(
        title: l10n.classesOrganisationErrorUnknown,
        subtitle: errorMessage ?? l10n.classesOrganisationErrorUnknown,
      );
    }

    final data = overview;
    if (data == null) {
      return ClassesOrganisationEmptyCard(
        title: l10n.classesOrganisationNoClassrooms,
        subtitle: l10n.classesOrganisationErrorUnknown,
      );
    }

    final classrooms = data.classrooms;
    if (classrooms.isEmpty) {
      return ClassesOrganisationEmptyCard(
        title: l10n.noResultsFound,
        subtitle: l10n.classesOrganisationNoClassrooms,
      );
    }

    final distributedCount = classrooms.fold<int>(
      0,
      (acc, item) => acc + item.members.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDimensions.spacingM),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            l10n.classesOrganisationSplitSummary(
              distributedCount,
              classrooms.length,
              l10n.classesOrganisationDistributionByGender,
            ),
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        if (data.unassignedEnrollments.isNotEmpty) ...[
          ClassesOrganisationUnassignedMembersSection(
            count: data.unassignedEnrollments.length,
            members: data.unassignedEnrollments
                .map(
                  (item) => ClassroomMember(
                    id: item.enrollmentId,
                    studentId: item.student.id,
                    classroomId: '',
                    academicYearId: '',
                    studentFirstName: item.student.firstName,
                    studentLastName: item.student.lastName,
                    studentMiddleName: item.student.surname,
                    studentGender: item.student.gender.name == 'female'
                        ? ClassroomMemberGender.female
                        : ClassroomMemberGender.male,
                  ),
                )
                .toList(growable: false),
            isReassigning: isReassigning,
            reassigningMemberId: reassigningMemberId,
            onTransferTap: onTransferTap,
          ),
          const SizedBox(height: AppDimensions.spacingM),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDimensions.spacingM),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.grid_view_rounded,
                size: AppDimensions.detailMiniIconSize,
                color: AppColors.bleuArdoise,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                l10n.classesOrganisationClassroomsSectionTitle,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.bleuArdoise,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 1080
                ? 3
                : width >= 700
                ? 2
                : 1;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: classrooms.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppDimensions.spacingM,
                mainAxisSpacing: AppDimensions.spacingM,
                childAspectRatio: AppDimensions.classesOrganisationGridRatio,
              ),
              itemBuilder: (context, index) {
                final bucket = classrooms[index];
                return ClassesOrganisationClassroomCard(
                  levelName: selectedLevel.schoolLevelName,
                  classroom: bucket.classroom,
                  members: bucket.members,
                  isReassigning: isReassigning,
                  reassigningMemberId: reassigningMemberId,
                  onTransferTap: onTransferTap,
                );
              },
            );
          },
        ),
      ],
    );
  }
}
