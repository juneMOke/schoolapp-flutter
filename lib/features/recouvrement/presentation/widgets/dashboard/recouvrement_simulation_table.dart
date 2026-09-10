import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_dashboard_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le verdict d'un groupe, dérivé du seuil courant.
enum RecouvrementVerdict { manageable, fragile, critical }

RecouvrementVerdict verdictOf(int keptPercent, int criticalPercent) {
  if (keptPercent < criticalPercent) return RecouvrementVerdict.critical;
  if (keptPercent < criticalPercent + RecouvrementSimulationState.fragileBand) {
    return RecouvrementVerdict.fragile;
  }
  return RecouvrementVerdict.manageable;
}

/// Les quatre chiffres de la simulation, puis le tableau groupe par groupe.
class RecouvrementSimulationTable extends StatelessWidget {
  final RecouvrementSimulation simulation;
  final int criticalPercent;
  final FeeControlDashboardLabels labels;
  final bool showCycleInLabels;
  final void Function(String? schoolLevelId)? onGroupTapped;

  const RecouvrementSimulationTable({
    super.key,
    required this.simulation,
    required this.criticalPercent,
    required this.labels,
    required this.showCycleInLabels,
    this.onGroupTapped,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EteeloKpiBand(cards: _cards(l10n)),
        const SizedBox(height: AppDimensions.spacingM),
        _Header(),
        for (final row in simulation.rows)
          _Row(
            row: row,
            criticalPercent: criticalPercent,
            label: labels.labelFor(
              row.schoolLevelId,
              l10n,
              withGroup: showCycleInLabels,
            ),
            onTap: row.targeted > 0 && onGroupTapped != null
                ? () => onGroupTapped!(row.schoolLevelId)
                : null,
          ),
      ],
    );
  }

  List<EteeloKpiCardData> _cards(AppLocalizations l10n) {
    final kept = simulation.keptPercent;
    final safe = kept >= criticalPercent;
    return [
      EteeloKpiCardData(
        label: l10n.recouvrementSimHeadcount,
        value: simulation.headcount,
        accent: AppColors.bleuArdoise,
        accentSoft: AppColors.bleuArdoiseSoft,
        icon: Icons.groups_outlined,
        subline: l10n.recouvrementSimHeadcountSubline,
      ),
      EteeloKpiCardData(
        label: l10n.recouvrementSimTargeted,
        value: simulation.targeted,
        accent: AppColors.error,
        accentSoft: AppColors.financeDetailDangerSoft,
        icon: Icons.person_remove_outlined,
      ),
      EteeloKpiCardData(
        label: l10n.recouvrementSimRemaining,
        value: simulation.remainingHeadcount,
        // La tuile change de teinte avec le verdict de la page : verte tant que
        // la mesure tient, rouge dès qu'elle ne tient plus.
        accent: safe ? AppColors.vertSavane : AppColors.error,
        accentSoft: safe
            ? AppColors.financeDetailSuccessSoft
            : AppColors.financeDetailDangerSoft,
        icon: Icons.group_outlined,
        subline: l10n.recouvrementSimRemainingSubline(kept),
      ),
      EteeloKpiCardData(
        label: l10n.recouvrementSimCritical,
        value: simulation.critical.length,
        accent: AppColors.warning,
        accentSoft: AppColors.financeCrossedSurface,
        icon: Icons.warning_amber_outlined,
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget cell(String text, int flex, {TextAlign align = TextAlign.start}) =>
        Expanded(
          flex: flex,
          child: Text(text, style: AppTextStyles.tableHeader, textAlign: align),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingS,
      ),
      child: Row(
        children: [
          cell(l10n.recouvrementSimTableGroup, 5),
          cell(l10n.recouvrementSimTableHeadcount, 2, align: TextAlign.end),
          cell(l10n.recouvrementSimTableLeaving, 2, align: TextAlign.end),
          cell(l10n.recouvrementSimTableRemaining, 2, align: TextAlign.end),
          cell(l10n.recouvrementSimTableKept, 4),
          cell(l10n.recouvrementSimTableVerdict, 3),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final RecouvrementSimulationRow row;
  final int criticalPercent;
  final String label;
  final VoidCallback? onTap;

  const _Row({
    required this.row,
    required this.criticalPercent,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final verdict = verdictOf(row.keptPercent, criticalPercent);
    final color = _color(verdict);

    return Semantics(
      // Un groupe dont personne ne part n'ouvre rien : ne pas l'annoncer
      // « bouton » évite d'offrir au clavier une cible qui ne fait rien.
      button: onTap != null,
      label: l10n.recouvrementSimRowA11y(
        label,
        row.keptPercent,
        _verdictLabel(verdict, l10n),
      ),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingS),
          child: Row(
            children: [
              Expanded(flex: 5, child: Text(label, style: AppTextStyles.body)),
              _num(row.headcount.toString(), 2),
              Expanded(
                flex: 2,
                child: Text(
                  // « −n » en rouge ; une ligne à zéro reste grise, pour que
                  // l'œil n'aille qu'aux groupes qui perdent des élèves.
                  row.targeted > 0 ? '−${row.targeted}' : '0',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.moneyTabular.copyWith(
                    color: row.targeted > 0
                        ? AppColors.error
                        : AppColors.textMuted,
                  ),
                ),
              ),
              _num(row.remainingHeadcount.toString(), 2),
              Expanded(
                flex: 4,
                child: _KeptBar(percent: row.keptPercent, color: color),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Icon(_icon(verdict), size: 16, color: color),
                    const SizedBox(width: AppDimensions.spacingXS),
                    Flexible(
                      child: Text(
                        _verdictLabel(verdict, l10n),
                        style: AppTextStyles.caption.copyWith(color: color),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _num(String text, int flex) => Expanded(
    flex: flex,
    child: Text(
      text,
      textAlign: TextAlign.end,
      style: AppTextStyles.moneyTabular,
    ),
  );

  static Color _color(RecouvrementVerdict verdict) => switch (verdict) {
    RecouvrementVerdict.manageable => AppColors.vertSavane,
    RecouvrementVerdict.fragile => AppColors.warning,
    RecouvrementVerdict.critical => AppColors.error,
  };

  /// Le verdict est **un texte avec icône**, jamais une couleur seule.
  static IconData _icon(RecouvrementVerdict verdict) => switch (verdict) {
    RecouvrementVerdict.manageable => Icons.check_circle_outline,
    RecouvrementVerdict.fragile => Icons.schedule,
    RecouvrementVerdict.critical => Icons.warning_amber_outlined,
  };

  static String _verdictLabel(
    RecouvrementVerdict verdict,
    AppLocalizations l10n,
  ) => switch (verdict) {
    RecouvrementVerdict.manageable => l10n.recouvrementVerdictManageable,
    RecouvrementVerdict.fragile => l10n.recouvrementVerdictFragile,
    RecouvrementVerdict.critical => l10n.recouvrementVerdictCritical,
  };
}

class _KeptBar extends StatelessWidget {
  final int percent;
  final Color color;

  const _KeptBar({required this.percent, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Container(
          height: AppDimensions.recouvrementKeptBarHeight,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(
              AppDimensions.recouvrementKeptBarHeight,
            ),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (percent / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(
                  AppDimensions.recouvrementKeptBarHeight,
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: AppDimensions.spacingS),
      Text('$percent %', style: AppTextStyles.moneyTabular),
    ],
  );
}
