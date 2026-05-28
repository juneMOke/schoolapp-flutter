import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingS,
      children: [
        SizedBox(
          width: AppDimensions.classesOrganisationCompactFieldWidth,
          child: _buildCycleField(l10n),
        ),
        SizedBox(
          width: AppDimensions.classesOrganisationCompactSelectWidth,
          child: _buildLevelField(l10n),
        ),
      ],
    );
  }

  Widget _buildCycleField(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      initialValue: selectedCycleId,
      isExpanded: true,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: _fieldDecoration(
        label: l10n.schoolCycle,
        icon: Icons.account_tree_outlined,
      ),
      items: cycles
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.id,
              child: Text(
                option.label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          )
          .toList(growable: false),
      onChanged: cycles.isEmpty
          ? null
          : (value) {
              onCycleChanged(value);
              onLevelChanged(null);
            },
    );
  }

  Widget _buildLevelField(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      initialValue: selectedLevelId,
      isExpanded: true,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: _fieldDecoration(
        label: l10n.schoolLevelLabel,
        icon: Icons.school_outlined,
      ),
      items: _availableLevels
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.key,
              child: Text(
                option.schoolLevelName,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          )
          .toList(growable: false),
      onChanged: _availableLevels.isEmpty
          ? null
          : (value) {
              ClassesOrganisationLevelOption? selected;
              for (final level in _availableLevels) {
                if (level.key == value) {
                  selected = level;
                  break;
                }
              }
              onLevelChanged(selected);
            },
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surfaceRaised,
      labelStyle: const TextStyle(color: AppColors.bleuArdoise),
      floatingLabelStyle: const TextStyle(color: AppColors.bleuArdoise),
      prefixIcon: Icon(icon, color: AppColors.bleuArdoise),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
        borderSide: const BorderSide(color: AppColors.bleuArdoise, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingM,
      ),
    );
  }
}
