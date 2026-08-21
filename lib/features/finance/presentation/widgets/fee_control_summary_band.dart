import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/fee_control/fee_control_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
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
                    child: EteeloKpiBand(cards: _cards(state, l10n)),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('fee-control-summary-off')),
        );
      },
    );
  }

  static List<EteeloKpiCardData> _cards(
    FeeControlState state,
    AppLocalizations l10n,
  ) {
    final breakdown = state.breakdown;
    final total = breakdown.total;

    return [
      EteeloKpiCardData(
        label: l10n.feeControlSummaryStudents,
        value: total,
        accent: AppColors.bleuArdoise,
        accentSoft: AppColors.billingHelpSurface,
        icon: Icons.groups_outlined,
      ),
      // Les trois autres cartes portent les libellés de statut de créance du
      // détail Facturation : « Payé » / « Partiel » / « À régler ». Un même état
      // ne doit pas changer de nom d'un écran à l'autre.
      _statusCard(
        count: breakdown.settled,
        total: total,
        status: StudentChargeStatus.paid,
        l10n: l10n,
      ),
      _statusCard(
        count: breakdown.partial,
        total: total,
        status: StudentChargeStatus.partial,
        l10n: l10n,
      ),
      _statusCard(
        count: breakdown.none,
        total: total,
        status: StudentChargeStatus.due,
        l10n: l10n,
      ),
    ];
  }

  static EteeloKpiCardData _statusCard({
    required int count,
    required int total,
    required StudentChargeStatus status,
    required AppLocalizations l10n,
  }) {
    final visuals = status.visuals;
    return EteeloKpiCardData(
      label: status.localizedLabel(l10n),
      value: count,
      percent: total <= 0 ? 0 : ((count * 100) / total).round(),
      accent: visuals.color,
      accentSoft: visuals.soft,
      icon: visuals.icon,
    );
  }
}
