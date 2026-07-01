import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_labels.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_eval_row.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_note_globale_bar.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_notation_atoms.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Panneau de la sélection (spec §4) : en-tête (médaillon + titre + statut +
/// nombre d'évaluations), synthèse « note globale », puis la liste d'évaluations
/// à plat (triée par date). Vide de bucket → note inline (spec §11).
class CoursBucketPanel extends StatelessWidget {
  final BucketVm bucket;
  final VoidCallback onOpenReleve;

  const CoursBucketPanel({
    super.key,
    required this.bucket,
    required this.onOpenReleve,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visual = bucketStatutVisual(bucket.statut);
    final label = bucketLabel(l10n, bucket);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brCard,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelHeader(bucket: bucket, label: label, visual: visual),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoursNoteGlobaleBar(
                    bucket: bucket,
                    label: label,
                    onOpenReleve: onOpenReleve,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (bucket.evaluations.isEmpty)
                    _BucketEmptyNote(statut: bucket.statut)
                  else
                    _EvalList(evaluations: bucket.evaluations),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final BucketVm bucket;
  final String label;
  final ({Color color, Color soft}) visual;

  const _PanelHeader({
    required this.bucket,
    required this.label,
    required this.visual,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [visual.soft, AppColors.surfaceRaised],
          stops: const [0, 0.7],
        ),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          _PanelMedallion(bucket: bucket, color: visual.color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      label,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    NotationPill(
                      color: visual.color,
                      soft: visual.soft,
                      label: statutLabel(l10n, bucket.statut),
                      pulseDot: bucket.statut == BucketStatut.current,
                      icon: _statutIcon(bucket.statut),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.courseDetailEvaluationCount(bucket.evalCount),
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

  IconData? _statutIcon(BucketStatut statut) => switch (statut) {
    BucketStatut.closed => Icons.check_circle_outline_rounded,
    BucketStatut.current => null,
    BucketStatut.upcoming => Icons.calendar_today_rounded,
  };
}

class _PanelMedallion extends StatelessWidget {
  final BucketVm bucket;
  final Color color;

  const _PanelMedallion({required this.bucket, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: _medallionChild(color),
    );
  }

  Widget _medallionChild(Color color) {
    if (bucket.kind == BucketKind.examen) {
      return Icon(Icons.school_outlined, size: 19, color: color);
    }
    if (bucket.statut == BucketStatut.closed) {
      return Icon(Icons.check_rounded, size: 19, color: color);
    }
    return Text(
      '${bucket.ordre}',
      style: AppTypography.titleSmall.copyWith(
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _EvalList extends StatelessWidget {
  final List<EvalVm> evaluations;

  const _EvalList({required this.evaluations});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brMd,
        child: Column(
          children: [
            for (var i = 0; i < evaluations.length; i++)
              CoursEvalRow(eval: evaluations[i], isFirst: i == 0),
          ],
        ),
      ),
    );
  }
}

class _BucketEmptyNote extends StatelessWidget {
  final BucketStatut statut;

  const _BucketEmptyNote({required this.statut});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = statut == BucketStatut.upcoming
        ? l10n.courseDetailBucketEmptyUpcoming
        : l10n.courseDetailBucketEmptyNone;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: AppColors.borderStrong,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
