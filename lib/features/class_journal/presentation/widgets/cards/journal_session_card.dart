import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/presentation/helpers/journal_display.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/common/journal_entry_details.dart';
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
    final hasDetails =
        JournalEntryDetails.filledOf(fields).isNotEmpty || line.chapter != null;
    return Semantics(
      button: onTap != null,
      label: journalLineSemantics(line, l10n),
      onTap: onTap,
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
                  if (hasDetails)
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: JournalEntryDetails(
                        fields: fields,
                        chapter: line.chapter,
                      ),
                    ),
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
