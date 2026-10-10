import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/presentation/helpers/journal_display.dart';
import 'package:school_app_flutter/features/class_journal/presentation/helpers/journal_field.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/common/journal_chapter_chip.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/common/journal_status_pill.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/sheet/journal_ruling_painter.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une séance de la feuille : l'heure (marge rouge), la branche et son statut,
/// puis les sept champs du cahier — tronqués à cinq lignes, « — » quand vides.
/// Toute la ligne ouvre la saisie.
class JournalSheetRow extends StatelessWidget {
  static const int _maxLines = 5;

  final JournalLine line;
  final VoidCallback? onTap;

  const JournalSheetRow({super.key, required this.line, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fields = line.entry?.fields ?? JournalFields.empty;
    return Semantics(
      button: onTap != null,
      label: journalLineSemantics(line, l10n),
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.stateHover,
          child: CustomPaint(
            painter: const JournalRulingPainter(),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.journalLine)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HourCell(line: line),
                    _BranchCell(line: line),
                    for (final field in JournalField.values)
                      Expanded(
                        flex: field.flex,
                        child: _FieldCell(
                          value: field.valueOf(fields),
                          chapter: field == JournalField.contenu
                              ? line.chapter
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HourCell extends StatelessWidget {
  final JournalLine line;

  const _HourCell({required this.line});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeStyle = AppTypography.labelSmall.copyWith(
      color: AppColors.textSecondary,
    );
    return Container(
      width: AppDimensions.journalHourColumn,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(
            color: AppColors.journalMargin,
            width: AppDimensions.journalMarginStroke,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            journalRankLabel(line, l10n),
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (line.slot case final slot?) ...[
            const SizedBox(height: AppSpacing.xs / 2),
            Text(journalHhmm(slot.startTime), style: timeStyle),
            Text(journalHhmm(slot.endTime), style: timeStyle),
          ],
        ],
      ),
    );
  }
}

class _BranchCell extends StatelessWidget {
  final JournalLine line;

  const _BranchCell({required this.line});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: AppDimensions.journalBranchColumn,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: AppDimensions.journalClassStripe,
            decoration: BoxDecoration(
              color: journalCourseColor(line),
              borderRadius: BorderRadius.circular(
                AppDimensions.journalClassStripe,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.subjectLabel,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  line.classroomLabel,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                JournalStatusPill(status: line.status),
                if (!line.scheduled) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.journalOffTimetable,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCell extends StatelessWidget {
  final String value;
  final JournalChapterTag? chapter;

  const _FieldCell({required this.value, this.chapter});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final empty = value.trim().isEmpty;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.journalLine)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            empty ? l10n.journalEmptyCell : value,
            maxLines: JournalSheetRow._maxLines,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: empty ? AppColors.borderStrong : AppColors.textPrimary,
            ),
          ),
          if (chapter case final tag?) ...[
            const SizedBox(height: AppSpacing.xs),
            JournalChapterChip(tag: tag),
          ],
        ],
      ),
    );
  }
}
