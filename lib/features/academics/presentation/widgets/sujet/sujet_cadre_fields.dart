import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/labels/form_section_label.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_duree_picker.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_programme_editor.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le cadre d'une évaluation (spec §4 bis) : durée, « Au programme »,
/// consignes. Mêmes champs dans la modale de création et l'éditeur du sujet.
class SujetCadreFields extends StatelessWidget {
  final int? dureeMinutes;
  final ValueChanged<int?> onDureeChanged;
  final List<String> programme;
  final ValueChanged<List<String>> onProgrammeChanged;
  final VoidCallback? onReprendreChapitres;
  final TextEditingController consignes;
  final VoidCallback? onConsignesChanged;

  const SujetCadreFields({
    super.key,
    required this.dureeMinutes,
    required this.onDureeChanged,
    required this.programme,
    required this.onProgrammeChanged,
    required this.consignes,
    this.onReprendreChapitres,
    this.onConsignesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSectionLabel(label: l10n.sujetDureeLabel),
        const SizedBox(height: AppSpacing.sm),
        SujetDureePicker(value: dureeMinutes, onChanged: onDureeChanged),
        const SizedBox(height: AppSpacing.lg),
        SujetProgrammeEditor(
          lines: programme,
          onChanged: onProgrammeChanged,
          onReprendreChapitres: onReprendreChapitres,
        ),
        const SizedBox(height: AppSpacing.md),
        FormSectionLabel(label: l10n.sujetConsignesLabel, optional: true),
        const SizedBox(height: AppSpacing.sm),
        EteeloTextInput(
          controller: consignes,
          label: l10n.sujetConsignesLabel,
          hideLabel: true,
          placeholder: l10n.sujetConsignesHint,
          keyboardType: EteeloTextInputType.multiline,
          minLines: 2,
          maxLines: 4,
          onChanged: onConsignesChanged == null
              ? null
              : (_) => onConsignesChanged!(),
        ),
      ],
    );
  }
}
