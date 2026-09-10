import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_dashboard_labels.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_simulation_controls.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_simulation_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Et si on renvoyait les impayés ? »
///
/// Le bloc le plus sensible de l'écran, et il répond en montrant d'abord ce que
/// la mesure **coûte** : l'effectif restant, groupe par groupe. Trois réglages,
/// quatre chiffres, un tableau.
///
/// **Rien n'est appliqué.** Aucun bouton « Appliquer », aucune action de masse :
/// le libellé de section le dit, et rien ici n'écrit en base. Appliquer un
/// renvoi passe par les Inscriptions, dossier par dossier.
class RecouvrementSimulationSection extends StatelessWidget {
  final FeeControlDashboardLabels labels;
  final bool showCycleInLabels;

  /// Ouvre la liste nominative du groupe. `null` tant que la sortie papier
  /// n'existe pas — une ligne sans destination ne se rend pas cliquable.
  final void Function(String? schoolLevelId)? onGroupTapped;

  const RecouvrementSimulationSection({
    super.key,
    required this.labels,
    required this.showCycleInLabels,
    this.onGroupTapped,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.figures != curr.figures,
      builder: (context, dashboard) {
        // Pas de simulation sans population : « 0 élève visé » sur un écran qui
        // n'a encore rien lu ne dit rien qu'on puisse arbitrer.
        if (dashboard.status != EnrollmentLoadStatus.success ||
            dashboard.figures.isEmpty) {
          return const SizedBox.shrink();
        }

        return BlocBuilder<
          RecouvrementSimulationCubit,
          RecouvrementSimulationState
        >(
          builder: (context, state) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            child: Semantics(
              container: true,
              label: l10n.recouvrementSimA11yLabel,
              child: BiToneSectionCard(
                title: l10n.recouvrementSimulationTitle,
                subtitle: l10n.recouvrementSimulationSubtitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const RecouvrementSimulationControls(),
                    const SizedBox(height: AppDimensions.spacingM),
                    RecouvrementSimulationTable(
                      simulation: state.result,
                      criticalPercent: state.criticalPercent,
                      labels: labels,
                      showCycleInLabels: showCycleInLabels,
                      onGroupTapped: onGroupTapped,
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    _FootNote(simulation: state.result),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Ce que la mesure coûte, en une phrase — et **deux montants qui ne
/// s'additionnent jamais**.
///
/// L'un est de l'argent déjà reçu que le renvoi rendrait sans objet ; l'autre de
/// l'argent qui ne viendra plus. Les sommer écrirait un chiffre qui ne désigne
/// rien.
class _FootNote extends StatelessWidget {
  final RecouvrementSimulation simulation;

  const _FootNote({required this.simulation});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (simulation.targeted == 0) return const SizedBox.shrink();

    final missing = _format(simulation.missing, l10n);
    final text = simulation.lost.isAllZero
        ? l10n.recouvrementSimFootNothingLost(missing)
        : l10n.recouvrementSimFootWithLoss(
            _format(simulation.lost, l10n),
            missing,
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  /// Les devises côte à côte, séparées par un point médian — jamais sommées.
  static String _format(MoneyBag bag, AppLocalizations l10n) => bag.isEmpty
      ? l10n.recouvrementNoAmountDash
      : bag.entries.map(MoneyFormat.format).join(' · ');
}
