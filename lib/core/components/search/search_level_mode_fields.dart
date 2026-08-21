import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/search_level_cascade.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/components/search/search_refine_name_field.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Champs du mode « Par classe » : la cascade Cycle → Niveau, puis l'affinage
/// par nom **facultatif**.
///
/// Les deux vont ensemble et nulle part ailleurs : c'est la classe qui ouvre la
/// recherche, le nom qui la restreint. Partagé par [BiModeSearchForm] et par
/// `FirstRegistrationSearchForm`, qui recompose les briques sans envelopper le
/// générique.
class SearchLevelModeFields extends StatelessWidget {
  final List<SearchCycle> cycles;
  final String? selectedGroupId;
  final String? selectedLevelKey;
  final bool isLoading;
  final String cycleLabel;
  final String levelLabel;
  final String levelPlaceholder;
  final ValueChanged<String?> onCycleChanged;
  final ValueChanged<String?> onLevelChanged;
  final TextEditingController refineNameController;
  final VoidCallback onRefineSubmitted;

  const SearchLevelModeFields({
    super.key,
    required this.cycles,
    required this.selectedGroupId,
    required this.selectedLevelKey,
    required this.isLoading,
    required this.cycleLabel,
    required this.levelLabel,
    required this.levelPlaceholder,
    required this.onCycleChanged,
    required this.onLevelChanged,
    required this.refineNameController,
    required this.onRefineSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchLevelCascade(
          cycles: cycles,
          selectedGroupId: selectedGroupId,
          selectedLevelKey: selectedLevelKey,
          isLoading: isLoading,
          cycleLabel: cycleLabel,
          levelLabel: levelLabel,
          levelPlaceholder: levelPlaceholder,
          onCycleChanged: onCycleChanged,
          onLevelChanged: onLevelChanged,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        SearchRefineNameField(
          controller: refineNameController,
          enabled: !isLoading,
          onSubmitted: (_) => onRefineSubmitted(),
        ),
      ],
    );
  }
}
