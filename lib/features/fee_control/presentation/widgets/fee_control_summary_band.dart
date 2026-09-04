import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/features/fee_control/presentation/helpers/fee_control_summary_cards.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bandeau de synthèse du Contrôle des frais : où en est la classe sur le frais
/// contrôlé — combien d'élèves concernés, combien soldés, partiels, sans
/// paiement.
///
/// Les compteurs portent sur **toute la population concernée**, pas sur la page
/// affichée ni sur le sous-ensemble filtré : filtrer sur « Soldé » ne doit pas
/// faire tomber « partiels » et « sans paiement » à zéro, sinon la synthèse ne
/// synthétise plus rien. C'est aussi pourquoi le bandeau reste visible quand le
/// tableau, lui, est vide.
///
/// Les teintes sont celles des statuts de frais ([StudentChargeStatusUiX]) :
/// une couleur veut dire la même chose ici et dans la pastille de chaque ligne.
class FeeControlSummaryBand extends StatelessWidget {
  const FeeControlSummaryBand({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<FeeControlBloc, FeeControlState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.breakdown != curr.breakdown,
      builder: (context, state) {
        // Rien à annoncer tant qu'aucun contrôle n'a abouti, et rien non plus
        // quand la classe ne porte pas ce frais — l'état vide des résultats le
        // dit déjà, et quatre zéros n'ajouteraient qu'un plancher de bruit.
        final show =
            state.status == EnrollmentLoadStatus.success &&
            !state.breakdown.isEmpty;

        return AnimatedSwitcher(
          duration: AppMotion.layout,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: show
              ? Padding(
                  key: const ValueKey('fee-control-summary'),
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.spacingM,
                  ),
                  child: Semantics(
                    container: true,
                    label: l10n.feeControlSummaryA11yLabel,
                    child: EteeloKpiBand(
                      cards: feeControlSummaryCards(state.breakdown, l10n),
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('fee-control-summary-off')),
        );
      },
    );
  }
}
