import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_labels.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_notation_atoms.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// En-tête résumé d'une évaluation (spec §6) : médaillon du type, eyebrow +
/// badge d'avancement, titre, rangée de chips (date · maximum · poids · classe ·
/// rattachement) et, le cas échéant, la ligne des chapitres.
class EvalSummaryCard extends StatelessWidget {
  final EvalDetailArgs args;

  const EvalSummaryCard({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final eval = args.eval;
    final typeVisual = evalTypeVisual(eval.type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Medallion(
            color: typeVisual.color,
            soft: typeVisual.soft,
            icon: typeVisual.icon,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EyebrowRow(eval: eval, color: typeVisual.color),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  eval.nom,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _ChipsRow(args: args),
                if (eval.chapitres.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _ChaptersLine(chapitres: eval.chapitres),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Medallion extends StatelessWidget {
  final Color color;
  final Color soft;
  final IconData icon;

  const _Medallion({
    required this.color,
    required this.soft,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(color: soft, borderRadius: AppRadius.brMd),
      child: Icon(icon, size: 25, color: color),
    );
  }
}

class _EyebrowRow extends StatelessWidget {
  final EvalVm eval;
  final Color color;

  const _EyebrowRow({required this.eval, required this.color});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          typeEvaluationLabel(l10n, eval.type).toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: color,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
          ),
        ),
        _AdvancementBadge(eval: eval),
      ],
    );
  }
}

class _AdvancementBadge extends StatelessWidget {
  final EvalVm eval;

  const _AdvancementBadge({required this.eval});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visual = evalStateVisual(eval.state);
    return switch (eval.state) {
      EvalState.complete => NotationPill(
        color: visual.color,
        soft: visual.soft,
        icon: Icons.check_circle_outline_rounded,
        label: l10n.evalBadgeComplete,
      ),
      EvalState.partial => NotationPill(
        color: visual.color,
        soft: visual.soft,
        icon: Icons.schedule_rounded,
        label: l10n.evalBadgePartial(eval.saisies, eval.total),
      ),
      EvalState.upcoming => NotationPill(
        color: visual.color,
        soft: visual.soft,
        icon: Icons.calendar_today_rounded,
        label: l10n.evalBadgeUpcoming,
      ),
    };
  }
}

class _ChipsRow extends StatelessWidget {
  final EvalDetailArgs args;

  const _ChipsRow({required this.args});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eval = args.eval;
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatCompactDate(eval.date);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        _EvalChip(label: dateLabel),
        _EvalChip(label: l10n.evalChipMax(formatPoints(eval.maxPoints))),
        _EvalChip(label: l10n.evalChipPoids(eval.poids)),
        _EvalChip(label: args.classroomName),
        _EvalChip(
          label: args.rattachementLabel,
          color: AppColors.academicsExamen,
          soft: AppColors.academicsExamenSoft,
        ),
      ],
    );
  }
}

/// Chip d'information de l'en-tête. Neutre par défaut (texte bleu ardoise sur
/// surface alt) ; teinté pour le rattachement (violet).
class _EvalChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? soft;

  const _EvalChip({required this.label, this.color, this.soft});

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.bleuArdoise;
    final bg = soft ?? AppColors.surfaceAlt;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChaptersLine extends StatelessWidget {
  final List<String> chapitres;

  const _ChaptersLine({required this.chapitres});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.menu_book_outlined,
            size: 14,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            chapitres.join(' · '),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
