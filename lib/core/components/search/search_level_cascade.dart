import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';

/// Sélecteur en cascade Cycle → Niveau.
///
/// Le dropdown Niveau reste désactivé tant qu'aucun cycle n'est choisi. Les
/// libellés sont fournis par l'appelant pour rester agnostique de la feature.
class SearchLevelCascade extends StatelessWidget {
  final List<SearchCycle> cycles;
  final String? selectedGroupId;
  final String? selectedLevelKey;
  final bool isLoading;
  final String cycleLabel;
  final String levelLabel;
  final String levelPlaceholder;
  final ValueChanged<String?> onCycleChanged;
  final ValueChanged<String?> onLevelChanged;

  const SearchLevelCascade({
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
  });

  @override
  Widget build(BuildContext context) {
    final activeCycle = cycles
        .where((cycle) => cycle.groupId == selectedGroupId)
        .firstOrNull;
    final levelOptions = activeCycle?.levels ?? const <SearchLevelOption>[];
    final cycleEnabled = !isLoading && cycles.isNotEmpty;
    final levelEnabled = !isLoading && activeCycle != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EteeloSelectInput<String>(
          label: cycleLabel,
          value: selectedGroupId,
          enabled: cycleEnabled,
          onChanged: onCycleChanged,
          items: cycles
              .map(
                (cycle) => EteeloSelectItem<String>(
                  value: cycle.groupId,
                  label: cycle.label,
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        EteeloSelectInput<String>(
          label: levelLabel,
          // Tant qu'aucun cycle n'est choisi, on invite à en choisir un.
          placeholder: levelEnabled ? null : levelPlaceholder,
          value: selectedLevelKey,
          enabled: levelEnabled,
          onChanged: onLevelChanged,
          items: levelOptions
              .map(
                (option) => EteeloSelectItem<String>(
                  value: option.key,
                  label: searchLevelShortLabel(option),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}
