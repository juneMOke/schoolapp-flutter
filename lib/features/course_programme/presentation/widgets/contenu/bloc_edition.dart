import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/bloc_visual.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/contenu_draft.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/programme_layout.dart';

/// Un bloc en édition : une carte avec son type, ses gestes (monter,
/// descendre, supprimer) et son champ — une ligne pour un titre, une zone de
/// texte sinon (une liste : un élément par ligne).
class BlocEdition extends StatelessWidget {
  final BlocLine line;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onDelete;

  const BlocEdition({
    super.key,
    required this.line,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = line.type;
    final multiline = type != ChapitreBlocType.titre;
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
              Icon(
                BlocVisual.icon(type),
                size: ProgrammeLayout.iconSmall,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  BlocVisual.label(l10n, type),
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (onMoveUp != null)
                IconButton(
                  tooltip: l10n.blocMoveUp,
                  onPressed: onMoveUp,
                  icon: const Icon(
                    Icons.arrow_upward_rounded,
                    size: ProgrammeLayout.iconMedium,
                  ),
                ),
              if (onMoveDown != null)
                IconButton(
                  tooltip: l10n.blocMoveDown,
                  onPressed: onMoveDown,
                  icon: const Icon(
                    Icons.arrow_downward_rounded,
                    size: ProgrammeLayout.iconMedium,
                  ),
                ),
              IconButton(
                tooltip: l10n.blocDelete,
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: ProgrammeLayout.iconMedium,
                ),
                color: AppColors.error,
              ),
            ],
          ),
          EteeloTextInput(
            controller: line.controller,
            label: BlocVisual.label(l10n, type),
            hideLabel: true,
            placeholder: BlocVisual.hint(l10n, type),
            keyboardType: multiline
                ? EteeloTextInputType.multiline
                : EteeloTextInputType.text,
            capitalization: EteeloTextCapitalization.sentence,
            minLines: multiline ? BlocVisual.minLines(type) : null,
            maxLines: multiline ? 12 : 1,
          ),
        ],
      ),
    );
  }
}
