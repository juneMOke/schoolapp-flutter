import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Sélecteurs en cascade Cycle → Niveau (composant Select du design-system).
///
/// Le Select Niveau reste désactivé tant qu'aucun cycle n'est choisi. Le choix
/// d'un cycle est remonté tel quel (la page réinitialise le niveau) ; le choix
/// d'un niveau est résolu en [ClassesOrganisationLevelOption] avant remontée.
class ClassesOrganisationCascadingSelectors extends StatelessWidget {
  final List<ClassesOrganisationCycleOption> cycles;
  final String? selectedCycleId;
  final String? selectedLevelId;
  final ValueChanged<String?> onCycleChanged;
  final ValueChanged<ClassesOrganisationLevelOption?> onLevelChanged;

  const ClassesOrganisationCascadingSelectors({
    required this.cycles,
    required this.selectedCycleId,
    required this.selectedLevelId,
    required this.onCycleChanged,
    required this.onLevelChanged,
    super.key,
  });

  ClassesOrganisationCycleOption? get _selectedCycle {
    final id = selectedCycleId;
    if (id == null) return null;
    for (final cycle in cycles) {
      if (cycle.id == id) return cycle;
    }
    return null;
  }

  List<ClassesOrganisationLevelOption> get _availableLevels =>
      _selectedCycle?.levels ?? const <ClassesOrganisationLevelOption>[];

  ClassesOrganisationLevelOption? _levelForKey(String? key) {
    if (key == null) return null;
    for (final level in _availableLevels) {
      if (level.key == key) return level;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final levelEnabled = _selectedCycle != null;

    final cycleField = EteeloSelectInput<String>(
      label: l10n.schoolCycle,
      value: selectedCycleId,
      enabled: cycles.isNotEmpty,
      onChanged: onCycleChanged,
      items: cycles
          .map(
            (option) =>
                EteeloSelectItem<String>(value: option.id, label: option.label),
          )
          .toList(growable: false),
    );

    final levelField = EteeloSelectInput<String>(
      label: l10n.schoolLevelLabel,
      value: selectedLevelId,
      enabled: levelEnabled,
      // Tant qu'aucun cycle n'est choisi, on invite à en prendre un.
      placeholder: levelEnabled
          ? null
          : l10n.classesOrganisationLevelPlaceholder,
      onChanged: (value) => onLevelChanged(_levelForKey(value)),
      items: _availableLevels
          .map(
            (option) => EteeloSelectItem<String>(
              value: option.key,
              label: option.schoolLevelName,
            ),
          )
          .toList(growable: false),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Large : les deux selects côte à côte ; étroit : empilés pleine largeur
        // (plus de largeurs fixes qui débordent / se clampent maladroitement).
        if (constraints.maxWidth < AppBreakpoints.classesCascadeRowMin) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cycleField,
              const SizedBox(height: AppDimensions.spacingS),
              levelField,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cycleField),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(child: levelField),
          ],
        );
      },
    );
  }
}
