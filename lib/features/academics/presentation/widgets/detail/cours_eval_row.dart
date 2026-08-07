import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_notation_atoms.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ligne d'évaluation (spec §5) : carré de type · identité · avancement · badge
/// de statut. Cliquable ([onTap] non nul → chevron) pour ouvrir la saisie des
/// notes (3ᵉ niveau).
class CoursEvalRow extends StatelessWidget {
  final EvalVm eval;
  final bool isFirst;
  final VoidCallback? onTap;

  const CoursEvalRow({
    super.key,
    required this.eval,
    required this.isFirst,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeVisual = evalTypeVisual(eval.type);
    final showChevron = onTap != null;
    const chevron = Icon(
      Icons.chevron_right_rounded,
      color: AppColors.bleuArdoise,
    );

    final identity = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eval.nom,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          l10n.courseDetailEvalMeta(
            formatEvalDate(context, eval.date),
            formatPoints(eval.maxPoints),
            eval.poids,
          ),
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    final content = Container(
      decoration: BoxDecoration(
        border: Border(
          top: isFirst
              ? BorderSide.none
              : const BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 460;
          final square = _TypeSquare(
            color: typeVisual.color,
            soft: typeVisual.soft,
            icon: typeVisual.icon,
          );
          final progress = _EvalProgress(eval: eval, color: typeVisual.color);
          final badge = _EvalBadge(eval: eval);

          if (narrow) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                square,
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      identity,
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [progress, badge],
                      ),
                    ],
                  ),
                ),
                if (showChevron) chevron,
              ],
            );
          }

          return Row(
            children: [
              square,
              const SizedBox(width: AppSpacing.md),
              Expanded(child: identity),
              const SizedBox(width: AppSpacing.md),
              progress,
              const SizedBox(width: AppSpacing.md),
              badge,
              if (showChevron) ...[
                const SizedBox(width: AppSpacing.sm),
                chevron,
              ],
            ],
          );
        },
      ),
    );

    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: eval.nom,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class _TypeSquare extends StatelessWidget {
  final Color color;
  final Color soft;
  final IconData icon;

  const _TypeSquare({
    required this.color,
    required this.soft,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 17, color: color),
    );
  }
}

class _EvalProgress extends StatelessWidget {
  final EvalVm eval;
  final Color color;

  const _EvalProgress({required this.eval, required this.color});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (eval.state == EvalState.upcoming) {
      return Text(
        l10n.courseDetailEvalExpected(eval.total),
        style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
      );
    }
    final fraction = (eval.pourcentageSaisie.clamp(0, 100)) / 100;
    return SizedBox(
      width: 120,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 5,
                child: ColoredBox(
                  color: AppColors.surfaceAlt,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction,
                    child: ColoredBox(color: color),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${eval.pourcentageSaisie.round()}%',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvalBadge extends StatelessWidget {
  final EvalVm eval;

  const _EvalBadge({required this.eval});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visual = evalStateVisual(eval.state);
    return switch (eval.state) {
      EvalState.complete => NotationPill(
        color: visual.color,
        soft: visual.soft,
        icon: Icons.check_circle_outline_rounded,
        label: l10n.courseDetailBadgeGraded,
      ),
      EvalState.partial => NotationPill(
        color: visual.color,
        soft: visual.soft,
        icon: Icons.schedule_rounded,
        label: l10n.courseDetailBadgeInProgress(eval.saisies, eval.total),
      ),
      EvalState.upcoming => NotationPill(
        color: visual.color,
        soft: visual.soft,
        icon: Icons.calendar_today_rounded,
        label: l10n.courseDetailBadgeUpcoming,
      ),
    };
  }
}
