import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_ranking_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux colonnes du bloc D, puis « Non affectés » à part.
class RecoveryClassRankingBody extends StatelessWidget {
  final RecoveryClassRanking ranking;
  final bool twoColumns;
  final bool narrow;
  final ValueChanged<RecoveryClassFeeRow> onClassTapped;

  const RecoveryClassRankingBody({
    super.key,
    required this.ranking,
    required this.twoColumns,
    required this.narrow,
    required this.onClassTapped,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final split = ranking.split();
    final unassigned = ranking.unassigned;
    final top = _Group(
      title: l10n.recoveryClassesTop,
      icon: Icons.trending_up,
      tone: AppColors.vertSavane,
      rows: split.top,
      narrow: narrow,
      onClassTapped: onClassTapped,
    );
    final bottom = _Group(
      title: l10n.recoveryClassesBottom,
      icon: Icons.warning_amber_rounded,
      tone: AppColors.error,
      rows: split.bottom,
      narrow: narrow,
      onClassTapped: onClassTapped,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ranking.ranked.isEmpty)
          RecoveryClassMuted(l10n.recoveryClassesNone)
        else if (twoColumns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: top),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: bottom),
            ],
          )
        else ...[
          top,
          const SizedBox(height: AppSpacing.lg),
          bottom,
        ],
        if (unassigned != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _GroupTitle(
            title: l10n.recoveryClassesUnassignedHeading,
            icon: Icons.person_off_outlined,
            tone: AppColors.textMutedAa,
          ),
          RecoveryClassRankingRow(
            row: unassigned,
            tone: AppColors.bleuArdoise,
            narrow: narrow,
            onTap: () => onClassTapped(unassigned),
          ),
        ],
      ],
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color tone;
  final List<RecoveryClassFeeRow> rows;
  final bool narrow;
  final ValueChanged<RecoveryClassFeeRow> onClassTapped;

  const _Group({
    required this.title,
    required this.icon,
    required this.tone,
    required this.rows,
    required this.narrow,
    required this.onClassTapped,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _GroupTitle(title: title, icon: icon, tone: tone),
      if (rows.isEmpty)
        RecoveryClassMuted(AppLocalizations.of(context)!.recoveryClassesSingle)
      else
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm - 2),
          RecoveryClassRankingRow(
            row: row,
            tone: tone,
            narrow: narrow,
            onTap: () => onClassTapped(row),
          ),
        ],
    ],
  );
}

class _GroupTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color tone;

  const _GroupTitle({
    required this.title,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Semantics(
      header: true,
      child: Row(
        children: [
          Icon(icon, size: AppSpacing.lg, color: tone),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              title.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMutedAa,
                letterSpacing: AppTypography.capsLetterSpacing,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Une ligne muette (« Une seule classe dans le périmètre. »).
class RecoveryClassMuted extends StatelessWidget {
  final String text;

  const RecoveryClassMuted(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTypography.bodySmall.copyWith(color: AppColors.textMutedAa),
  );
}
