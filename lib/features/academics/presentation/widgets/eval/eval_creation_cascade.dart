import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_labels.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_creation_rules.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Cascade période scolaire → sous-période de la modale de création (spec §3).
/// Examen : la sous-période est désactivée, placeholder « Examen semestriel ».
class EvalCreationCascade extends StatelessWidget {
  final EvalCreationRules rules;
  final ValueChanged<String?> onPeriodeChanged;
  final ValueChanged<String?> onSousPeriodeChanged;

  const EvalCreationCascade({
    super.key,
    required this.rules,
    required this.onPeriodeChanged,
    required this.onSousPeriodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Découpage dérivé du nombre de périodes (mêmes libellés que la page détail).
    final decoupage = periodeDecoupageFromCount(rules.periodes.length);
    final isExamen = rules.isExamen;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: EteeloSelectInput<String>(
            label: decoupageFieldLabel(l10n, decoupage),
            value: rules.periodeId,
            onChanged: onPeriodeChanged,
            errorText: rules.isPeriodeClosed
                ? l10n.evalCreateClosedPeriodError
                : null,
            items: [
              for (final p in rules.periodes)
                EteeloSelectItem<String>(
                  value: p.periodeScolaireId,
                  label: periodeScolaireLabel(l10n, p.ordre, decoupage),
                  // Verrou de clôture (bundle, DF-M) : une période CLOTUREE ne
                  // peut plus recevoir de saisie — grisée, pas seulement
                  // bloquée après coup par errorText/submit.
                  enabled: p.statut != StatutPeriode.cloturee,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: EteeloSelectInput<String>(
            label: l10n.evalCreateFieldSousPeriode,
            value: isExamen ? null : rules.sousPeriodeId,
            enabled: !isExamen,
            placeholder: isExamen ? l10n.evalCreateExamPlaceholder : null,
            // Erreur affichée ici seulement si le blocage vient de la
            // sous-période (sinon il est déjà signalé sur la période scolaire).
            errorText:
                (!isExamen &&
                    !rules.isPeriodeClosed &&
                    rules.isSousPeriodeClosed)
                ? l10n.evalCreateClosedPeriodError
                : null,
            onChanged: onSousPeriodeChanged,
            items: [
              for (final sp in rules.periode?.sousPeriodes ?? const [])
                EteeloSelectItem<String>(
                  value: sp.sousPeriodeId,
                  label: l10n.courseDetailPeriodLabel(sp.ordre),
                  // Verrou de clôture (bundle, DF-M) : idem période, une
                  // sous-période CLOTUREE est grisée dans le picker.
                  enabled: sp.statut != StatutPeriode.cloturee,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
