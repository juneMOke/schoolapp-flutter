import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/labels/form_section_label.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/chapitre_form_model.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/chapitre_strategies.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/form/chapitre_form_sections.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les stratégies d'intervention : le catalogue en puces à choix multiple
/// (une coche, pas seulement la couleur), plus une saisie libre — Entrée ou
/// « Ajouter » — sans doublon.
class ChapitreStrategiesField extends StatelessWidget {
  final ChapitreFormModel model;
  final VoidCallback onChanged;

  const ChapitreStrategiesField({
    super.key,
    required this.model,
    required this.onChanged,
  });

  void _addCustom() {
    model.addCustomStrategy();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = chapitreStrategyCatalog(l10n);
    final custom = [
      for (final s in model.strategies)
        if (!catalog.contains(s)) s,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSectionLabel(
          label: l10n.chapitreFormStrategiesLabel,
          optional: true,
          count: model.strategies.length,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final strategy in [...catalog, ...custom])
              _StrategyChip(
                label: strategy,
                selected: model.strategies.contains(strategy),
                onTap: () {
                  model.toggleStrategy(strategy);
                  onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: model.strategyDraft,
                builder: (context, _, _) => EteeloTextInput(
                  controller: model.strategyDraft,
                  label: l10n.chapitreFormStrategyHint,
                  hideLabel: true,
                  placeholder: l10n.chapitreFormStrategyHint,
                  capitalization: EteeloTextCapitalization.sentence,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addCustom(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: model.strategyDraft,
              builder: (context, value, _) => ChapitreFormAddButton(
                onPressed: value.text.trim().isEmpty ? null : _addCustom,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Une puce de stratégie : coche + bleu ardoise quand elle est retenue.
class _StrategyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StrategyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => EteeloFilterChip(
    label: label,
    selected: selected,
    color: AppColors.bleuArdoise,
    soft: AppColors.bleuArdoiseSoft,
    ink: AppColors.bleuArdoise,
    icon: selected ? Icons.check_rounded : null,
    onTap: onTap,
  );
}
