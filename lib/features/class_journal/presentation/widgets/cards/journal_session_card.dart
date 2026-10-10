import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/presentation/helpers/journal_display.dart';
import 'package:school_app_flutter/features/class_journal/presentation/helpers/journal_field.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/common/journal_chapter_chip.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/common/journal_status_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une séance en carte : rang, branche · classe, créneau, statut, puis les
/// seuls champs remplis en « libellé / valeur ». Toute la carte ouvre la
/// saisie.
class JournalSessionCard extends StatelessWidget {
  final JournalLine line;
  final VoidCallback? onTap;

  const JournalSessionCard({super.key, required this.line, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fields = line.entry?.fields ?? JournalFields.empty;
    final filled = [
      for (final field in JournalField.values)
        if (field.valueOf(fields).trim().isNotEmpty) field,
    ];
    return Semantics(
      button: onTap != null,
      label: journalLineSemantics(line, l10n),
      excludeSemantics: true,
      child: Material(
        color: AppColors.surfaceRaised,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.brLg,
          side: BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: journalCourseColor(line),
                  width: AppDimensions.journalCardStripe,
                ),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppDimensions.journalCardMinHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CardHeader(line: line, interactive: onTap != null),
                  if (filled.isNotEmpty || line.chapter != null)
                    _CardDetails(line: line, fields: fields, filled: filled),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final JournalLine line;
  final bool interactive;

  const _CardHeader({required this.line, required this.interactive});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Text(
            journalRankLabel(line, l10n),
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.journalCourseTitle(
                    line.subjectLabel,
                    line.classroomLabel,
                  ),
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  line.scheduled
                      ? journalSlotRange(line, l10n)
                      : '${journalSlotRange(line, l10n)} · '
                            '${l10n.journalOffTimetable}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          JournalStatusPill(status: line.status),
          if (interactive)
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }
}

class _CardDetails extends StatelessWidget {
  final JournalLine line;
  final JournalFields fields;
  final List<JournalField> filled;

  const _CardDetails({
    required this.line,
    required this.fields,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labelStyle = AppTypography.bodySmall.copyWith(
      color: AppColors.textSecondary,
    );
    final valueStyle = AppTypography.bodySmall.copyWith(
      color: AppColors.textPrimary,
    );
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final field in filled)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: AppDimensions.journalCardLabelColumn,
                    child: Text(field.label(l10n), style: labelStyle),
                  ),
                  Expanded(
                    child: Text(field.valueOf(fields), style: valueStyle),
                  ),
                ],
              ),
            ),
          if (line.chapter case final tag?) JournalChapterChip(tag: tag),
        ],
      ),
    );
  }
}
