import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Synthèse « note globale » d'un bucket (spec §4) : moyenne de classe + taux
/// de réussite + chip « provisoire » si des notes manquent + accès au relevé
/// par élève (« Par élève »).
class CoursNoteGlobaleBar extends StatelessWidget {
  final BucketVm bucket;
  final String label;
  final VoidCallback onOpenReleve;

  const CoursNoteGlobaleBar({
    super.key,
    required this.bucket,
    required this.label,
    required this.onOpenReleve,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showReleve =
        bucket.supportsReleve && bucket.moyennesEleves.isNotEmpty;

    final medallion = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.academicsStatutClosedSoft,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: AppColors.academicsStatutClosed.withValues(alpha: 0.25),
        ),
      ),
      child: const Icon(
        Icons.trending_up_rounded,
        size: 17,
        color: AppColors.academicsStatutClosed,
      ),
    );

    final texts = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.courseDetailNoteGlobaleTitle(label),
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (bucket.isProvisoire)
              _ProvisionalChip(label: l10n.courseDetailProvisional),
          ],
        ),
        const SizedBox(height: 2),
        _AverageLine(bucket: bucket),
      ],
    );

    final button = EteeloButton.secondary(
      label: l10n.courseDetailByStudent,
      icon: Icons.groups_outlined,
      onPressed: onOpenReleve,
      fullWidth: false,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 420;
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    medallion,
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: texts),
                  ],
                ),
                if (showReleve) ...[
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: Center(child: button),
                  ),
                ],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              medallion,
              const SizedBox(width: AppSpacing.md),
              Expanded(child: texts),
              if (showReleve) ...[const SizedBox(width: AppSpacing.md), button],
            ],
          );
        },
      ),
    );
  }
}

class _AverageLine extends StatelessWidget {
  final BucketVm bucket;

  const _AverageLine({required this.bucket});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final base = AppTypography.labelSmall.copyWith(color: AppColors.textMuted);

    final moyenne = bucket.moyenneClasse;
    if (moyenne == null) {
      return Text(l10n.courseDetailNoAverage, style: base);
    }

    final tone = scoreTone(moyenne);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: '${l10n.courseDetailClassAverageLabel} '),
          TextSpan(
            text: formatPercent(moyenne),
            style: base.copyWith(
              color: tone.color,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (bucket.nombreElevesNotes > 0)
            TextSpan(
              text:
                  ' · ${l10n.courseDetailAbove50(bucket.nombreEleves50, bucket.nombreElevesNotes)}',
            ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ProvisionalChip extends StatelessWidget {
  final String label;

  const _ProvisionalChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brPill,
        border: Border.all(
          color: AppColors.academicsStatutCurrent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 11,
            color: AppColors.academicsStatutCurrent,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.academicsStatutCurrent,
            ),
          ),
        ],
      ),
    );
  }
}
