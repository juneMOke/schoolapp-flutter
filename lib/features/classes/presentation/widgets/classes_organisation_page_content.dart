import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_distribution_criterion.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_organisation_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_members_loading_indicator.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_mode_info_banner.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_page_header.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_results_section.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_search_form.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';

class ClassesOrganisationPageContent extends StatelessWidget {
  final List<ClassesOrganisationLevelOption> options;
  final ClassesOrganisationSearchRequest? lastRequest;
  final ValueChanged<ClassesOrganisationSearchRequest> onSearch;
  final void Function(
    ClassroomDistributionCriterion criterion,
    ClassesOrganisationLevelOption level,
  )
  onDistributionRequested;
  final void Function(Object summary, String levelId) onViewRequested;
  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;

  const ClassesOrganisationPageContent({
    super.key,
    required this.options,
    required this.lastRequest,
    required this.onSearch,
    required this.onDistributionRequested,
    required this.onViewRequested,
    required this.onTransferTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSplit = lastRequest?.selectedLevel?.splitIntoClassrooms ?? false;

    return AnimatedSwitcher(
      duration: AppMotion.standard,
      switchInCurve: AppMotion.outCurve,
      switchOutCurve: AppMotion.inCurve,
      child: Column(
        key: ValueKey<String>('classes-organisation-$isSplit'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ClassesOrganisationPageHeader(),
          const SizedBox(height: AppDimensions.spacingM),
          BlocBuilder<ClassroomBloc, ClassroomState>(
            buildWhen: ClassesOrganisationPageHelpers.buildWhenSearchFormChanges,
            builder: (context, classroomState) {
              return BlocBuilder<EnrollmentBloc, EnrollmentState>(
                buildWhen: (previous, current) =>
                    previous.summariesStatus != current.summariesStatus,
                builder: (context, enrollmentState) {
                  return ClassesOrganisationSearchForm(
                    options: options,
                    isSearching: ClassesOrganisationPageHelpers.isSearching(
                      classroomState,
                      enrollmentState,
                      lastRequest,
                    ),
                    isDistributing:
                        classroomState.distributionStatus == ClassroomStatus.loading,
                    onSearch: onSearch,
                    onDistributionRequested: onDistributionRequested,
                  );
                },
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacingM),
          ClassesOrganisationModeInfoBanner(isSplit: isSplit),
          const SizedBox(height: AppDimensions.spacingS),
          if (isSplit) const ClassesOrganisationMembersLoadingIndicator(),
          AnimatedSwitcher(
            duration: AppMotion.standard,
            switchInCurve: AppMotion.outCurve,
            switchOutCurve: AppMotion.inCurve,
            child: KeyedSubtree(
              key: ValueKey('classes-results-$isSplit'),
              child: ClassesOrganisationResultsSection(
                isSplit: isSplit,
                lastRequest: lastRequest,
                onViewRequested: onViewRequested,
                onTransferTap: onTransferTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
