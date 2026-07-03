import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_labels.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_notation_atoms.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Frise des buckets (spec §3) : sous-périodes + examen d'une période, en pas
/// sélectionnables. Le pas sélectionné prend la teinte de son statut.
class CoursBucketTimeline extends StatelessWidget {
  final List<BucketVm> buckets;
  final String selectedKey;
  final ValueChanged<String> onSelect;

  static const double _minStepWidth = 168;

  const CoursBucketTimeline({
    super.key,
    required this.buckets,
    required this.selectedKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final width = constraints.maxWidth;
        final rawColumns = (width + gap) ~/ (_minStepWidth + gap);
        final columns = rawColumns < 1
            ? 1
            : (rawColumns > buckets.length ? buckets.length : rawColumns);
        final stepWidth = columns <= 1
            ? width
            : (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final bucket in buckets)
              SizedBox(
                width: stepWidth,
                child: _Step(
                  bucket: bucket,
                  selected: bucket.key == selectedKey,
                  onTap: () => onSelect(bucket.key),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Step extends StatelessWidget {
  final BucketVm bucket;
  final bool selected;
  final VoidCallback onTap;

  const _Step({
    required this.bucket,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visual = bucketStatutVisual(bucket.statut);
    final label = bucketLabel(l10n, bucket);

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, ${statutLabel(l10n, bucket.statut)}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.brLg,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: selected ? visual.soft : AppColors.surfaceRaised,
              borderRadius: AppRadius.brLg,
              border: Border.all(
                color: selected ? visual.color : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                _StepMedallion(bucket: bucket, color: visual.color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              style: AppTypography.labelLarge.copyWith(
                                color: selected
                                    ? visual.color
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (bucket.statut == BucketStatut.current) ...[
                            const SizedBox(width: AppSpacing.sm),
                            NotationPulseDot(color: visual.color),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _legend(l10n),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _legend(AppLocalizations l10n) {
    if (bucket.kind == BucketKind.examen &&
        bucket.statut == BucketStatut.upcoming) {
      return l10n.courseDetailExamToPlan;
    }
    if (bucket.evalCount == 0) {
      return l10n.courseDetailBucketNoEval;
    }
    return l10n.courseDetailBucketNotes(
      bucket.saisiesNotes,
      bucket.totalNotes,
      bucket.evalCount,
    );
  }
}

class _StepMedallion extends StatelessWidget {
  final BucketVm bucket;
  final Color color;

  const _StepMedallion({required this.bucket, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.brSm,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: _child(),
    );
  }

  Widget _child() {
    if (bucket.kind == BucketKind.examen) {
      return Icon(Icons.school_outlined, size: 16, color: color);
    }
    if (bucket.statut == BucketStatut.closed) {
      return Icon(Icons.check_rounded, size: 15, color: color);
    }
    return Text(
      '${bucket.ordre}',
      style: AppTypography.labelMedium.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
