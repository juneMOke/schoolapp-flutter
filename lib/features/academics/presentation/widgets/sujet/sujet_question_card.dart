import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_limits.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/sujet_draft_controller.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_notation_atoms.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_question_tile.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une question en édition (spec S3) : « Q{n} », points, actions (monter,
/// descendre, dupliquer, supprimer), énoncé, puis la réponse attendue dans sa
/// zone verte. Rien n'est écrit avant « Enregistrer le sujet » : la
/// suppression ne demande pas de confirmation.
/// Points : chiffres et un séparateur décimal, deux décimales au plus — le
/// serveur refuse au-delà.
final TextInputFormatter _pointsFormatter = TextInputFormatter.withFunction(
  (previous, next) =>
      RegExp(r'^\d{0,5}([.,]\d{0,2})?$').hasMatch(next.text) ? next : previous,
);

final TextInputFormatter _textLimit = LengthLimitingTextInputFormatter(
  SujetLimits.questionTextMaxLength,
);

class SujetQuestionCard extends StatelessWidget {
  final SujetQuestionDraft draft;
  final int number;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<int> onMove;

  /// `null` : le sujet a atteint son nombre de questions.
  final VoidCallback? onDuplicate;
  final VoidCallback onDelete;

  const SujetQuestionCard({
    super.key,
    required this.draft,
    required this.number,
    required this.isFirst,
    required this.isLast,
    required this.onMove,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SujetQuestionBadge(number),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: AppDimensions.sujetPointsFieldWidth,
                child: EteeloTextInput(
                  controller: draft.points,
                  label: l10n.sujetQuestionPointsLabel(number),
                  hideLabel: true,
                  placeholder: l10n.sujetPointsSuffix,
                  keyboardType: EteeloTextInputType.number,
                  inputFormatters: [_pointsFormatter],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.sujetPointsSuffix,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              if (draft.toQuestion().isIncomplete) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: NotationPill(
                    color: AppColors.academicsScoreWeak,
                    soft: AppColors.academicsScoreWeakSoft,
                    label: l10n.sujetIncomplete,
                  ),
                ),
              ],
              const Spacer(),
              if (!isFirst)
                _action(
                  Icons.arrow_upward_rounded,
                  l10n.sujetMoveUp,
                  () => onMove(-1),
                ),
              if (!isLast)
                _action(
                  Icons.arrow_downward_rounded,
                  l10n.sujetMoveDown,
                  () => onMove(1),
                ),
              if (onDuplicate != null)
                _action(Icons.copy_rounded, l10n.sujetDuplicate, onDuplicate!),
              _action(
                Icons.delete_outline_rounded,
                l10n.sujetDelete,
                onDelete,
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          EteeloTextInput(
            controller: draft.enonce,
            label: l10n.sujetQuestionEnonceLabel(number),
            hideLabel: true,
            placeholder: l10n.sujetQuestionEnonceHint,
            keyboardType: EteeloTextInputType.multiline,
            minLines: 2,
            maxLines: 6,
            inputFormatters: [_textLimit],
          ),
          const SizedBox(height: AppSpacing.sm),
          SujetAnswerBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.sujetAnswerHeader,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.academicsScoreGood,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                EteeloTextInput(
                  controller: draft.reponse,
                  label: l10n.sujetAnswerHeader,
                  hideLabel: true,
                  placeholder: l10n.sujetAnswerHint,
                  keyboardType: EteeloTextInputType.multiline,
                  minLines: 2,
                  maxLines: 6,
                  inputFormatters: [_textLimit],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    Color color = AppColors.textSecondary,
  }) => SizedBox.square(
    dimension: AppDimensions.sujetIconAction,
    child: IconButton(
      padding: EdgeInsets.zero,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: AppDimensions.sujetIconSize, color: color),
    ),
  );
}
