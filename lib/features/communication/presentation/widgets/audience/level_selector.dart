import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';

/// Les niveaux, cochables, groupés par cycle (Primaire · Secondaire).
class LevelSelector extends StatelessWidget {
  final List<SchoolLevelGroupBundle> groups;
  final List<String> selected;
  final ValueChanged<String>? onToggle;

  const LevelSelector({
    super.key,
    required this.groups,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final toggle = onToggle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final bundle in groups)
          if (bundle.levels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Semantics(
                container: true,
                label: bundle.group.name,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bundle.group.name,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final level in bundle.levels)
                          EteeloFilterChip(
                            label: level.name,
                            selected: selected.contains(level.id),
                            color: AppColors.bleuArdoise,
                            soft: AppColors.bleuArdoiseSoft,
                            ink: AppColors.bleuArdoise,
                            onTap: toggle == null
                                ? null
                                : () => toggle(level.id),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
