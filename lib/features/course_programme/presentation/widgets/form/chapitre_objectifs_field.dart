import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/labels/form_section_label.dart';
import 'package:school_app_flutter/core/components/fields/numbered_line_row.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
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
        FormSectionLabel(
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
            child: NumberedLineRow(
              number: i + 1,
              controller: lines[i].controller,
              label: l10n.chapitreFormObjectifLabel(i + 1),
              placeholder: l10n.chapitreFormObjectifHint,
              removeTooltip: l10n.chapitreFormObjectifRemove,
              onRemove: lines.length > 1
                  ? () {
                      model.removeObjectif(lines[i]);
                      onChanged();
                    }
                  : null,
            ),
          ),
      ],
    );
  }
}
