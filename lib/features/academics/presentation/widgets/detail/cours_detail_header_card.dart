import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_class_visual.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// En-tête du cours (spec §1) : médaillon de classe, branche, classe, chips
/// (effectif · évaluations · « à saisir ») et encart « Prochaine évaluation ».
/// Liséré gauche 5 dp à la couleur de la classe.
class CoursDetailHeaderCard extends StatelessWidget {
  final String brancheNom;
  final String classroomName;
  final AcademicsClassVisual visual;
  final CoursNotationViewModel viewModel;

  const CoursDetailHeaderCard({
    super.key,
    required this.brancheNom,
    required this.classroomName,
    required this.visual,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    // Liséré gauche via fond accent révélé sur 5 dp (cf. accordéon Mes cours :
    // pas de Row `stretch`, qui planterait dans une vue défilante).
    return ClipRRect(
      borderRadius: AppRadius.brCard,
      child: ColoredBox(
        color: visual.accent,
        child: Padding(
          padding: const EdgeInsets.only(left: 5),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surfaceRaised,
              border: Border(
                top: BorderSide(color: AppColors.border),
                right: BorderSide(color: AppColors.border),
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 560;
                  final identity = _Identity(
                    brancheNom: brancheNom,
                    classroomName: classroomName,
                    visual: visual,
                    viewModel: viewModel,
                  );
                  final next = viewModel.prochaineEval == null
                      ? null
                      : _NextEvalCard(eval: viewModel.prochaineEval!);

                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        identity,
                        if (next != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          next,
                        ],
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: identity),
                      if (next != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: next,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final String brancheNom;
  final String classroomName;
  final AcademicsClassVisual visual;
  final CoursNotationViewModel viewModel;

  const _Identity({
    required this.brancheNom,
    required this.classroomName,
    required this.visual,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: visual.soft,
            borderRadius: AppRadius.brMd,
          ),
          child: Icon(Icons.menu_book_rounded, size: 26, color: visual.accent),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                brancheNom,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                classroomName,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _HeaderChip(
                    icon: Icons.people_alt_outlined,
                    label: l10n.myCoursesStudentCount(viewModel.effectif),
                    color: AppColors.bleuArdoise,
                    soft: AppColors.surfaceAlt,
                  ),
                  _HeaderChip(
                    label: l10n.courseDetailEvaluationCount(
                      viewModel.totalEvaluations,
                    ),
                    color: AppColors.bleuArdoise,
                    soft: AppColors.surfaceAlt,
                  ),
                  if (viewModel.aSaisir > 0)
                    _HeaderChip(
                      icon: Icons.edit_outlined,
                      label: l10n.courseDetailToGrade(viewModel.aSaisir),
                      color: AppColors.warning,
                      soft: AppColors.academicsStatutCurrentSoft,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final Color soft;

  const _HeaderChip({
    this.icon,
    required this.label,
    required this.color,
    required this.soft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.chipPaddingH,
        vertical: AppDimensions.chipPaddingV,
      ),
      decoration: BoxDecoration(color: soft, borderRadius: AppRadius.brSm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextEvalCard extends StatelessWidget {
  final EvalVm eval;

  const _NextEvalCard({required this.eval});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.courseDetailNextEvalEyebrow.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.terreCuite,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            eval.nom,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            l10n.courseDetailEvalMetaShort(
              formatEvalDate(context, eval.date),
              formatPoints(eval.maxPoints),
            ),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
