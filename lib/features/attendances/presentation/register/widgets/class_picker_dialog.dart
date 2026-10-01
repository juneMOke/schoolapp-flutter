import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_classroom.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/helpers/class_picker_options.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Choisir la classe de l'appel : le cycle en segment, puis tous ses niveaux
/// et leurs classes en un écran — une modale à la place des trois listes en
/// cascade d'avant. Rend la classe choisie, ou `null`.
class ClassPickerDialog extends StatefulWidget {
  final List<ClassPickerCycle> cycles;

  /// La classe affichée : la modale s'ouvre sur son cycle et la coche.
  final String? selectedId;

  const ClassPickerDialog({super.key, required this.cycles, this.selectedId});

  @override
  State<ClassPickerDialog> createState() => _ClassPickerDialogState();
}

class _ClassPickerDialogState extends State<ClassPickerDialog> {
  late String _cycleId = _initialCycle();

  String _initialCycle() {
    final selected = widget.selectedId;
    for (final cycle in widget.cycles) {
      if (selected != null && cycle.contains(selected)) return cycle.id;
    }
    return widget.cycles.isEmpty ? '' : widget.cycles.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cycle = widget.cycles.firstWhere(
      (c) => c.id == _cycleId,
      orElse: () => widget.cycles.first,
    );
    return EteeloFormDialog(
      eyebrow: l10n.classPresencePickerEyebrow,
      title: l10n.classPresencePickClass,
      maxWidth: AppDimensions.classPickerDialogMaxWidth,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.cycles.length > 1) ...[
            SegmentedTabFilter<String>(
              semanticsLabel: l10n.classPresencePickClass,
              selected: cycle.id,
              onSelected: (id) => setState(() => _cycleId = id),
              options: [
                for (final c in widget.cycles)
                  SegmentedTabOption(label: c.label, value: c.id),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          for (final level in cycle.levels) ...[
            Text(
              level.label.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMutedAa,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final classroom in level.classrooms)
                  _ClassButton(
                    classroom: classroom,
                    selected: classroom.id == widget.selectedId,
                    onTap: () => Navigator.of(
                      context,
                    ).pop<ClassPresenceClassroom>(level.classroomOf(classroom)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
      actions: [
        EteeloButton.ghost(
          label: l10n.presenceMarkCancel,
          onPressed: () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
      ],
    );
  }
}

class _ClassButton extends StatelessWidget {
  final OfflineClassroom classroom;
  final bool selected;
  final VoidCallback onTap;

  const _ClassButton({
    required this.classroom,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.stateHover : AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brLg,
          side: BorderSide(
            color: selected ? AppColors.bleuArdoise : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const RoundedRectangleBorder(
            borderRadius: AppRadius.brLg,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.classPickerClassHeight,
              minWidth: AppDimensions.classPickerClassMinWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    classroom.name,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.classPresenceStudentsShort(classroom.totalCount),
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.check,
                      size: AppSpacing.lg,
                      color: AppColors.bleuArdoise,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
