import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_overflow_text.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_zone_rows.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La colonne figée de gauche : les cours, leurs domaines, les libellés de pied.
class CoteGridCourseZone extends StatelessWidget {
  final CoteGridContext grid;

  const CoteGridCourseZone({super.key, required this.grid});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final heights = grid.heights;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (grid.hasGroupTotals)
          Container(height: heights.group, color: AppColors.blancCasse),
        _HeaderCell(
          label: l10n.coteColumnCours.toUpperCase(),
          height: heights.header,
        ),
        for (final row in grid.rows)
          switch (row) {
            final CoteRubriqueRow r => _DomainLabel(row: r, grid: grid),
            final CoteCourseRow r => _CourseLabel(row: r, grid: grid),
          },
        _FootLabel(
          label: l10n.coteMaxima.toUpperCase(),
          height: heights.maxima,
          background: AppColors.blancCasse,
          style: coteMaximaStyle(),
        ),
        _FootLabel(
          label: l10n.coteTotalObtained.toUpperCase(),
          height: heights.total,
          background: AppColors.bleuProfond,
          style: coteDarkRowStyle(),
        ),
        if (grid.hasGroupTotals)
          _FootLabel(
            label: l10n.cotePercentRow.toUpperCase(),
            height: heights.percent,
            background: AppColors.bleuArdoise,
            style: coteDarkRowStyle(),
          ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final double height;

  const _HeaderCell({required this.label, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        color: AppColors.blancCasse,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DomainLabel extends StatelessWidget {
  final CoteRubriqueRow row;
  final CoteGridContext grid;

  const _DomainLabel({required this.row, required this.grid});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: grid.heights.domain,
      color: row.tone.soft,
      padding: EdgeInsets.only(
        left: AppSpacing.md + row.depth * AppSpacing.sm,
        right: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.coteDomainMark,
            height: AppDimensions.coteDomainMark,
            decoration: BoxDecoration(
              color: row.tone.ink,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: EteeloOverflowText(
              (row.rubrique.label ?? '').toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: row.tone.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseLabel extends StatelessWidget {
  final CoteCourseRow row;
  final CoteGridContext grid;

  const _CourseLabel({required this.row, required this.grid});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cours = row.cours;
    final scale = cours.hasExamen
        ? l10n.coteCourseScale('${cours.maxJournalier}', '${cours.maxExamen}')
        : l10n.coteCourseScaleNoExam('${cours.maxJournalier}');
    return Container(
      height: grid.heights.course,
      padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xs),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.coteCourseMarkWidth,
            height: AppDimensions.coteCourseMarkHeight,
            color: row.tone.ink.withValues(alpha: 0.55),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EteeloOverflowText(
                  cours.branche,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.noirChaud,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                EteeloOverflowText(
                  scale,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FootLabel extends StatelessWidget {
  final String label;
  final double height;
  final Color background;
  final TextStyle style;

  const _FootLabel({
    required this.label,
    required this.height,
    required this.background,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
