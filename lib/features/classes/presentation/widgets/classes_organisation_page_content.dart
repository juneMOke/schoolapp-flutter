import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_results_section.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_search_form.dart';

class ClassesOrganisationPageContent extends StatelessWidget {
  final List<ClassesOrganisationCycleOption> cycles;
  final String? selectedCycleId;
  final ClassesOrganisationLevelOption? selectedLevel;
  final bool isDistributing;
  final VoidCallback onDistributionRequested;
  final ValueChanged<String?> onCycleChanged;
  final ValueChanged<ClassesOrganisationLevelOption?> onLevelChanged;
  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;

  const ClassesOrganisationPageContent({
    super.key,
    required this.cycles,
    required this.selectedCycleId,
    required this.selectedLevel,
    required this.isDistributing,
    required this.onDistributionRequested,
    required this.onCycleChanged,
    required this.onLevelChanged,
    required this.onTransferTap,
  });

  @override
  Widget build(BuildContext context) {
    final cycle = _selectedCycle(cycles, selectedCycleId);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.detailContentMaxWidth,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacingL,
            0,
            AppDimensions.spacingL,
            AppDimensions.spacingL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassesOrganisationSearchForm(
                cycles: cycles,
                selectedCycleId: selectedCycleId,
                selectedLevelId: selectedLevel?.key,
                onCycleChanged: onCycleChanged,
                onLevelChanged: onLevelChanged,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              ClassesOrganisationResultsSection(
                selectedCycle: cycle,
                selectedLevel: selectedLevel,
                isDistributing: isDistributing,
                onDistributionRequested: onDistributionRequested,
                onTransferTap: onTransferTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  ClassesOrganisationCycleOption? _selectedCycle(
    List<ClassesOrganisationCycleOption> all,
    String? id,
  ) {
    if (id == null) return null;
    for (final cycle in all) {
      if (cycle.id == id) return cycle;
    }
    return null;
  }
}
