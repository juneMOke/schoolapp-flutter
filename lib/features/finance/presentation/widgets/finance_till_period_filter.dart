import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La fenêtre que la caisse totalise — **jour par défaut**.
///
/// C'est la question qu'on pose le soir, à la fermeture. Les trois autres
/// grains répondent à la même question sur une fenêtre plus large ; aucun ne
/// demande d'attendu, puisque tout y est déjà encaissé.
///
/// Le recouvrement, lui, n'a plus de sélecteur : à la semaine, les échéances
/// tombant en fin de mois, l'attendu valait zéro.
///
/// ⚠️ Aucune **ancre** n'est envoyée : les quatre grains portent toujours la
/// fenêtre courante. Le jour où l'écran proposera de viser une journée passée,
/// l'ancre devra être remise à zéro à chaque changement de grain — le serveur
/// refuse en 400 une ancre qui ne correspond pas à la période.
class FinanceTillPeriodFilter extends StatelessWidget {
  const FinanceTillPeriodFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<FinanceTillBloc, FinanceTillState>(
      buildWhen: (prev, curr) => prev.selectedPeriod != curr.selectedPeriod,
      builder: (context, state) {
        final selectedLabel = _labelOf(state.selectedPeriod, l10n);

        return Semantics(
          container: true,
          label: l10n.financeStatsPeriodFilterA11yLabel(selectedLabel),
          child: SegmentedTabFilter<TillPeriod>(
            options: [
              for (final period in TillPeriod.values)
                SegmentedTabOption(
                  label: _labelOf(period, l10n),
                  value: period,
                ),
            ],
            selected: state.selectedPeriod,
            onSelected: (period) => context.read<FinanceTillBloc>().add(
              FinanceTillRequested(period: period),
            ),
          ),
        );
      },
    );
  }

  String _labelOf(TillPeriod period, AppLocalizations l10n) => switch (period) {
    TillPeriod.day => l10n.financeTillPeriodDayCurrent,
    TillPeriod.week => l10n.financeStatsPeriodWeekCurrent,
    TillPeriod.month => l10n.financeStatsPeriodMonthCurrent,
    TillPeriod.year => l10n.financeStatsPeriodYearCurrent,
  };
}
