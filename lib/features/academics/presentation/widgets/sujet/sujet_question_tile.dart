import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une question en lecture (spec S2) : « Q{n} », énoncé, points, et l'œil qui
/// révèle la réponse attendue — masquée par défaut.
class SujetQuestionTile extends StatelessWidget {
  final int number;
  final SujetQuestion question;
  final bool answerVisible;
  final VoidCallback onToggleAnswer;

  const SujetQuestionTile({
    super.key,
    required this.number,
    required this.question,
    required this.answerVisible,
    required this.onToggleAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final answer = question.reponseAttendue;
    final points = question.points;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SujetQuestionBadge(number),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  question.enonce,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (points != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.sujetQuestionPoints(formatPoints(points)),
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (answer != null)
                SizedBox.square(
                  dimension: AppDimensions.sujetIconAction,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: answerVisible
                        ? l10n.sujetHideAnswer
                        : l10n.sujetRevealAnswer,
                    onPressed: onToggleAnswer,
                    style: IconButton.styleFrom(
                      backgroundColor: answerVisible
                          ? AppColors.academicsAnswerSoft
                          : null,
                    ),
                    icon: Icon(
                      answerVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: AppDimensions.sujetIconSize,
                      color: answerVisible
                          ? AppColors.academicsScoreGood
                          : AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          if (answer != null && answerVisible)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                left: AppDimensions.sujetNumberBadge + AppSpacing.sm,
              ),
              child: SujetAnswerBox(
                child: Text(
                  l10n.sujetAnswerRead(answer),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pastille « Q{n} » d'une question.
class SujetQuestionBadge extends StatelessWidget {
  final int number;

  const SujetQuestionBadge(this.number, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: AppDimensions.sujetNumberBadge,
    constraints: const BoxConstraints(minWidth: AppDimensions.sujetNumberBadge),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    decoration: const BoxDecoration(
      color: AppColors.bleuArdoiseSoft,
      borderRadius: AppRadius.brSm,
    ),
    child: Text(
      AppLocalizations.of(context)!.sujetQuestionBadge(number),
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.bleuArdoise,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Zone teintée verte de la réponse attendue — visible du professeur seul.
class SujetAnswerBox extends StatelessWidget {
  final Widget child;

  const SujetAnswerBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.academicsAnswerSoft,
      borderRadius: AppRadius.brSm,
      border: Border.all(color: AppColors.academicsAnswerBorder),
    ),
    child: child,
  );
}
