import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_dashboard_labels.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_fee_options.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Trois lectures en fin de page : ce que les chiffres **impliquent**.
///
/// Chacune est **calculée**, jamais rédigée en dur, et chacune se fonde sur un
/// bloc visible plus haut — sans quoi elle affirmerait quelque chose que
/// l'écran ne montre pas.
///
/// **Aucune n'ordonne une sanction.** Elles chiffrent le coût d'une option et
/// nomment l'alternative ; c'est la différence entre un tableau de bord et une
/// injonction.
///
/// Rendues seulement en `ready` : ni pendant le chargement — on ne squelettise
/// pas du texte interprétatif — ni sur un écran vide, où il n'y aurait rien à
/// interpréter.
class RecouvrementInsightsSection extends StatelessWidget {
  final FeeControlDashboardLabels labels;
  final bool showCycleInLabels;

  /// Le titre que l'école donne à chaque nature : la lecture nomme le poste
  /// comme la section du taux, juste au-dessus.
  final FeeSectionTitlesState titles;

  /// Ouvre l'écran nominatif sur le frais le plus en retard.
  final void Function(String feeCode)? onControlRequested;

  const RecouvrementInsightsSection({
    super.key,
    required this.labels,
    required this.showCycleInLabels,
    this.titles = const FeeSectionTitlesState(),
    this.onControlRequested,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.rates != curr.rates ||
          prev.ranking != curr.ranking,
      builder: (context, dashboard) {
        if (dashboard.status != EnrollmentLoadStatus.success ||
            dashboard.figures.isEmpty) {
          return const SizedBox.shrink();
        }

        return BlocBuilder<
          RecouvrementSimulationCubit,
          RecouvrementSimulationState
        >(
          buildWhen: (prev, curr) => prev.result != curr.result,
          builder: (context, simulation) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            child: Wrap(
              spacing: AppDimensions.spacingM,
              runSpacing: AppDimensions.spacingM,
              children: [
                ?_latestFee(context, dashboard, l10n),
                ?_spread(context, dashboard, l10n),
                _simulationReading(simulation, l10n),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Le poste dont le taux est le plus bas — celui qu'on va contrôler.
  ///
  /// Les postes sans attendu sont écartés : leur taux vaut 100 et ne veut rien
  /// dire, et les classer premiers ferait désigner un poste dormant.
  Widget? _latestFee(
    BuildContext context,
    RecouvrementDashboardState dashboard,
    AppLocalizations l10n,
  ) {
    final fees = [
      for (final group in dashboard.rates)
        for (final fee in group.fees)
          if (!fee.hasNoExpectation) fee,
    ];
    if (fees.isEmpty) return null;

    final worst = fees.reduce((a, b) => a.rate <= b.rate ? a : b);
    return _Insight(
      icon: Icons.percent,
      accent: AppColors.error,
      accentSoft: AppColors.financeDetailDangerSoft,
      title: l10n.recouvrementInsightWorstFeeTitle,
      body: l10n.recouvrementInsightWorstFeeBody(
        recouvrementFeeTitle(worst.feeCode, titles, l10n),
        worst.rate,
        MoneyFormat.format(Money(worst.remainingInCents, worst.currency)),
      ),
      actionLabel: onControlRequested == null
          ? null
          : l10n.recouvrementInsightControlAction,
      onAction: onControlRequested == null
          ? null
          : () => onControlRequested!(worst.feeCode),
    );
  }

  /// L'écart entre le groupe en tête et celui qui ferme la marche.
  ///
  /// Muette sous deux groupes : un écart entre un groupe et lui-même n'existe
  /// pas, et l'annoncer à zéro serait une phrase pour rien.
  Widget? _spread(
    BuildContext context,
    RecouvrementDashboardState dashboard,
    AppLocalizations l10n,
  ) {
    final groups = dashboard.ranking.groups;
    if (groups.length < 2) return null;

    // Le classement est trié du plus en retard au plus en règle : les deux
    // bouts sont donc les extrêmes, sans re-trier.
    final worst = groups.first;
    final best = groups.last;
    if (worst.settledPercent == best.settledPercent) return null;

    return _Insight(
      icon: Icons.school_outlined,
      accent: AppColors.bleuArdoise,
      accentSoft: AppColors.bleuArdoiseSoft,
      title: l10n.recouvrementInsightSpreadTitle,
      body: l10n.recouvrementInsightSpreadBody(
        best.settledPercent,
        labels.labelFor(best.schoolLevelId, l10n, withGroup: showCycleInLabels),
        worst.settledPercent,
        labels.labelFor(
          worst.schoolLevelId,
          l10n,
          withGroup: showCycleInLabels,
        ),
      ),
    );
  }

  /// Ce que la simulation implique — et **ce qu'elle coûterait**.
  ///
  /// Le ton change avec le résultat, jamais la conclusion : aucune des deux
  /// formulations n'ordonne un renvoi.
  Widget _simulationReading(
    RecouvrementSimulationState simulation,
    AppLocalizations l10n,
  ) {
    final critical = simulation.result.critical.length;
    if (critical == 0) {
      return _Insight(
        icon: Icons.check_circle_outline,
        accent: AppColors.vertSavane,
        accentSoft: AppColors.financeDetailSuccessSoft,
        title: l10n.recouvrementInsightSimulationTitle,
        body: l10n.recouvrementInsightSimulationSafe(
          simulation.result.remainingHeadcount,
          simulation.result.keptPercent,
        ),
      );
    }

    return _Insight(
      icon: Icons.warning_amber_outlined,
      accent: AppColors.error,
      accentSoft: AppColors.financeDetailDangerSoft,
      title: l10n.recouvrementInsightSimulationTitle,
      body: l10n.recouvrementInsightSimulationCritical(
        critical,
        simulation.criticalPercent,
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Insight({
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(
      minWidth: AppDimensions.recouvrementInsightMinWidth,
      maxWidth: AppDimensions.recouvrementInsightMaxWidth,
    ),
    child: Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppDimensions.recouvrementInsightMedallion,
                height: AppDimensions.recouvrementInsightMedallion,
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(AppDimensions.spacingS),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(child: Text(title, style: AppTextStyles.bodyStrong)),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            body,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppDimensions.spacingS),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}
