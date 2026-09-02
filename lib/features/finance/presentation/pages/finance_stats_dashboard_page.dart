import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_recovery_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_dashboard_tabs.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_recovery_tab.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_dashboard_header.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_tab.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le tableau de bord Finances — **deux onglets, deux questions**.
///
/// « Où en est-on de l'argent qu'on doit encaisser cette année ? » et « combien
/// est entré dans le tiroir ? » ne se posent jamais en même temps. Elles ont
/// pourtant partagé un écran et un sélecteur de période, jusqu'à ce que le
/// serveur les sépare en deux routes.
///
/// La page reste **la même** — même chemin, même entrée de menu, même
/// permission. Un sous-menu séparé aurait buté sur un droit : la caisse se lit
/// sous `finance.stats.read`, qu'un caissier boutique ne détient pas ; il
/// n'aurait pas vu le total de ses propres ventes dans un menu qui lui est
/// ouvert.
class FinanceStatsDashboardPage extends StatefulWidget {
  const FinanceStatsDashboardPage({super.key});

  @override
  State<FinanceStatsDashboardPage> createState() =>
      _FinanceStatsDashboardPageState();
}

class _FinanceStatsDashboardPageState extends State<FinanceStatsDashboardPage> {
  FinanceDashboardTab _tab = FinanceDashboardTab.recovery;

  /// L'onglet Caisse n'a encore jamais été ouvert.
  ///
  /// **Chargement paresseux, et ce n'est pas une micro-optimisation :** deux
  /// appels au montage, sur une liaison de guichet, c'est deux fois le délai
  /// avant le premier chiffre — pour un écran dont on ne lit qu'une moitié.
  bool _tillRequested = false;

  @override
  void initState() {
    super.initState();
    context.read<FinanceRecoveryBloc>().add(const FinanceRecoveryRequested());
  }

  void _onTabSelected(FinanceDashboardTab tab) {
    if (tab == _tab) return;

    // La caisse se demande **une fois**, à la première ouverture. Les allers et
    // retours suivants entre les onglets ne rappellent rien : ce que l'écran
    // affiche est ce qui a été lu, et la ligne de fraîcheur dira son âge.
    if (tab == FinanceDashboardTab.till && !_tillRequested) {
      _tillRequested = true;
      context.read<FinanceTillBloc>().add(const FinanceTillRequested());
    }

    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPageBackground(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<FinanceRecoveryBloc, FinanceRecoveryState>(
            buildWhen: (prev, curr) => prev.recovery != curr.recovery,
            builder: (context, state) => FinanceStatsDashboardHeader(
              schoolYear: state.recovery?.context.schoolYear,
              l10n: l10n,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          FinanceDashboardTabs(selected: _tab, onSelected: _onTabSelected),
          const SizedBox(height: AppDimensions.spacingL),
          AnimatedSwitcher(
            duration: AppMotion.standard,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey<FinanceDashboardTab>(_tab),
              child: switch (_tab) {
                FinanceDashboardTab.recovery => const FinanceRecoveryTab(),
                FinanceDashboardTab.till => const FinanceTillTab(),
              },
            ),
          ),
        ],
      ),
    );
  }
}
