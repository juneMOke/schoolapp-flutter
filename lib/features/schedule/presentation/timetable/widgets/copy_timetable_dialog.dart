import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/touch_target.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/copy_source.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/timetable_copy_plan.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// O3 — copier un emploi du temps (R8) : les sources de même grille en choix
/// exclusif, puis l'aperçu (reprises, conflits, sans équivalent) calculé sur
/// l'appareil par la même fonction que la copie. Rend la source choisie.
class CopyTimetableDialog extends StatefulWidget {
  final ClassTimetableView target;
  final List<CopySource> sources;

  const CopyTimetableDialog({
    super.key,
    required this.target,
    required this.sources,
  });

  @override
  State<CopyTimetableDialog> createState() => _CopyTimetableDialogState();
}

class _CopyTimetableDialogState extends State<CopyTimetableDialog> {
  CopySource? _source;

  void _submit() {
    final source = _source;
    if (source != null) Navigator.of(context).pop(source);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final source = _source;
    final plan = source == null
        ? null
        : TimetableCopyPlan.of(widget.target, source);
    return EteeloFormDialog(
      eyebrow: l10n.classTimetableCopyEyebrow(widget.target.classroom.name),
      title: l10n.classTimetableCopyTitle,
      onSubmit: source == null ? null : _submit,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.sources.isEmpty)
            Text(l10n.classTimetableCopyNone, style: AppTypography.bodyMedium),
          for (final s in widget.sources)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: EteeloActivatable(
                onActivate: () => setState(() => _source = s),
                semanticLabel: s.classroom.name,
                builder: (context, highlight) => TouchTarget(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: highlight.any
                          ? AppColors.terreCuiteSoft
                          : AppColors.surfaceRaised,
                      borderRadius: AppRadius.brSm,
                      border: Border.all(
                        color: s == source
                            ? AppColors.terreCuite
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          s == source
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: s == source
                              ? AppColors.terreCuite
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.classroom.name,
                                style: AppTypography.bodyMedium,
                              ),
                              Text(
                                l10n.classTimetableCopySource(
                                  s.sessionCount,
                                  s.isDraft
                                      ? l10n.classTimetableDraft
                                      : l10n.classTimetablePublished,
                                ),
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (plan != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.classTimetableCopyTaken(plan.result.taken),
              style: AppTypography.bodyMedium,
            ),
            Text(
              l10n.classTimetableCopyConflicts(plan.result.conflicts),
              style: AppTypography.bodySmall,
            ),
            Text(
              l10n.classTimetableCopyNoEquivalent(plan.result.noEquivalent),
              style: AppTypography.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          EteeloNotice.warning(l10n.classTimetableCopyNotice),
        ],
      ),
      actions: [
        SecondaryButton(
          label: l10n.classTimetableCancel,
          fullWidth: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
        PrimaryButton(
          label: l10n.classTimetableCopySubmit,
          fullWidth: false,
          onPressed: source == null ? null : _submit,
        ),
      ],
    );
  }
}
