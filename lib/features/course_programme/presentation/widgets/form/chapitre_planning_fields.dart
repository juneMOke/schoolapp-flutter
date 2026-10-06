import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_edit.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/chapitre_form_model.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';

/// Rattachement (sous-période) et séances prévues, côte à côte quand la
/// largeur le permet.
class ChapitrePlanningFields extends StatelessWidget {
  final ChapitreFormModel model;
  final List<SousPeriodeOption> sousPeriodes;
  final bool touched;
  final VoidCallback onChanged;

  const ChapitrePlanningFields({
    super.key,
    required this.model,
    required this.sousPeriodes,
    required this.touched,
    required this.onChanged,
  });

  static const double _fieldMinWidth = 180;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sousPeriode = EteeloSelectInput<String?>(
      label: l10n.chapitreFormSousPeriodeLabel,
      value: model.sousPeriodeId,
      items: [
        EteeloSelectItem<String?>(
          value: null,
          label: l10n.chapitreFormSousPeriodeNone,
        ),
        for (final option in sousPeriodes)
          EteeloSelectItem<String?>(
            value: option.id,
            label: l10n.courseDetailPeriodLabel(option.ordre),
          ),
      ],
      onChanged: (value) {
        model.sousPeriodeId = value;
        onChanged();
      },
    );
    final seances = EteeloTextInput(
      controller: model.seances,
      label: l10n.chapitreFormSeancesLabel,
      placeholder: '${Chapitre.defaultSeances}',
      keyboardType: EteeloTextInputType.number,
      errorText: touched && model.seancesInvalid
          ? l10n.chapitreFormSeancesInvalid
          : null,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _fieldMinWidth * 2 + AppSpacing.md) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sousPeriode,
              const SizedBox(height: AppSpacing.md),
              seances,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: sousPeriode),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: seances),
          ],
        );
      },
    );
  }
}
