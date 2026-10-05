import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/chapitre_form_model.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/form/chapitre_form_sections.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les objectifs d'apprentissage : des lignes numérotées, « + Ajouter », un
/// ✕ dès qu'il y en a plus d'une. Une ligne vide est ignorée à
/// l'enregistrement.
class ChapitreObjectifsField extends StatelessWidget {
  final ChapitreFormModel model;
  final VoidCallback onChanged;

  const ChapitreObjectifsField({
    super.key,
    required this.model,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lines = model.objectifs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChapitreFormLabel(
          label: l10n.chapitreFormObjectifsLabel,
          optional: true,
          action: ChapitreFormAddButton(
            onPressed: () {
              model.addObjectif();
              onChanged();
            },
          ),
        ),
        for (var i = 0; i < lines.length; i++)
          Padding(
            key: ValueKey<String>(lines[i].id),
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              children: [
                _Numero(i + 1),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: EteeloTextInput(
                    controller: lines[i].controller,
                    label: '${l10n.chapitreFormObjectifsLabel} ${i + 1}',
                    hideLabel: true,
                    placeholder: l10n.chapitreFormObjectifHint,
                    capitalization: EteeloTextCapitalization.sentence,
                  ),
                ),
                if (lines.length > 1)
                  IconButton(
                    tooltip: l10n.chapitreFormObjectifRemove,
                    onPressed: () {
                      model.removeObjectif(lines[i]);
                      onChanged();
                    },
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.error,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Numero extends StatelessWidget {
  final int value;

  const _Numero(this.value);

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: AppSpacing.xl,
      height: AppSpacing.xl,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        '$value',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
