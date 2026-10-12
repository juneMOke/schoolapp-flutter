import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_referential.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une rangée par niveau : toucher le libellé du niveau coche ou décoche
/// toutes ses classes.
class ClassroomSelector extends StatelessWidget {
  final List<SchoolLevelGroupBundle> groups;
  final AudienceReferential referential;
  final List<String> selected;
  final ValueChanged<String>? onToggle;
  final ValueChanged<List<String>>? onToggleLevel;

  const ClassroomSelector({
    super.key,
    required this.groups,
    required this.referential,
    required this.selected,
    required this.onToggle,
    required this.onToggleLevel,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final bundle in groups)
        for (final level in bundle.levels)
          (label: level.name, rooms: referential.classroomsOf(level.id)),
    ].where((row) => row.rooms.isNotEmpty).toList();
    if (rows.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.communicationNoClassroom,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      );
    }
    final toggle = onToggle;
    final toggleLevel = onToggleLevel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  onPressed: toggleLevel == null
                      ? null
                      : () => toggleLevel([for (final r in row.rooms) r.id]),
                  child: Text(row.label),
                ),
                for (final room in row.rooms)
                  EteeloFilterChip(
                    label: room.name,
                    selected: selected.contains(room.id),
                    color: AppColors.bleuArdoise,
                    soft: AppColors.bleuArdoiseSoft,
                    ink: AppColors.bleuArdoise,
                    onTap: toggle == null ? null : () => toggle(room.id),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
