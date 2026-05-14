import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_list_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_results_section.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_search_form.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';

class ClassesListPageContent extends StatelessWidget {
  final List<ClassesListCycleOption> options;
  final ClassesListSearchRequest? lastRequest;
  final ValueChanged<ClassesListSearchRequest> onSearch;
  final VoidCallback onExportPressed;
  final ValueChanged<EnrollmentSummary> onEnrollmentViewRequested;
  final ValueChanged<ClassroomMember> onClassroomMemberViewRequested;

  const ClassesListPageContent({
    super.key,
    required this.options,
    required this.lastRequest,
    required this.onSearch,
    required this.onExportPressed,
    required this.onEnrollmentViewRequested,
    required this.onClassroomMemberViewRequested,
  });

  @override
  Widget build(BuildContext context) {
    final searchModeKey = lastRequest?.targetsClassroom == true
        ? 'classes-list-classroom-mode'
        : 'classes-list-level-mode';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<ClassroomBloc, ClassroomState>(
          buildWhen: (previous, current) =>
              previous.membersStatus != current.membersStatus,
          builder: (context, classroomState) {
            return BlocBuilder<EnrollmentBloc, EnrollmentState>(
              buildWhen: (previous, current) =>
                  previous.summariesStatus != current.summariesStatus,
              builder: (context, enrollmentState) {
                return ClassesListSearchForm(
                  options: options,
                  isSearching: ClassesListPageHelpers.isSearching(
                    enrollmentState: enrollmentState,
                    classroomState: classroomState,
                    lastRequest: lastRequest,
                  ),
                  onSearch: onSearch,
                );
              },
            );
          },
        ),
        const SizedBox(height: AppDimensions.spacingM),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey<String>('results-$searchModeKey'),
            child: ClassesListResultsSection(
              lastRequest: lastRequest,
              onExportPressed: onExportPressed,
              onEnrollmentViewRequested: onEnrollmentViewRequested,
              onClassroomMemberViewRequested: onClassroomMemberViewRequested,
            ),
          ),
        ),
      ],
    );
  }
}