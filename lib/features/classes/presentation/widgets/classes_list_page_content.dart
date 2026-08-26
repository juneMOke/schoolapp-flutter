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
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';

class ClassesListPageContent extends StatelessWidget {
  final List<ClassesListCycleOption> options;
  final ClassesListSearchRequest? lastRequest;
  final ValueChanged<ClassesListSearchRequest> onSearch;
  final VoidCallback onExportPressed;
  final ValueChanged<int> onPageRequested;
  final ValueChanged<EnrollmentSummary> onEnrollmentViewRequested;
  final ValueChanged<ClassroomMember> onClassroomMemberViewRequested;

  const ClassesListPageContent({
    super.key,
    required this.options,
    required this.lastRequest,
    required this.onSearch,
    required this.onExportPressed,
    required this.onPageRequested,
    required this.onEnrollmentViewRequested,
    required this.onClassroomMemberViewRequested,
  });

  @override
  Widget build(BuildContext context) {
    // Trois formes de résultats, trois clés : le roster d'une classe, la liste
    // d'un niveau, et la liste par identité — qui porte une colonne de plus.
    // Les confondre ferait hériter la nouvelle liste de l'état de tri de
    // l'ancienne, sur des colonnes qui ne sont pas les mêmes.
    final searchModeKey = switch (lastRequest) {
      null => 'classes-list-initial',
      final request when request.targetsClassroom => 'classes-list-classroom',
      final request when request.isIdentityMode => 'classes-list-identity',
      _ => 'classes-list-level',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<ClassroomBloc, ClassroomState>(
          buildWhen: (previous, current) =>
              previous.membersStatus != current.membersStatus,
          builder: (context, classroomState) {
            return BlocBuilder<
              EnrollmentLocalListBloc,
              EnrollmentLocalListState
            >(
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
              onPageRequested: onPageRequested,
              onEnrollmentViewRequested: onEnrollmentViewRequested,
              onClassroomMemberViewRequested: onClassroomMemberViewRequested,
            ),
          ),
        ),
      ],
    );
  }
}
