import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_dashboard_header.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_tab.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le tableau de bord Finances : **la caisse**, et elle seule.
///
/// « Combien est entré dans le tiroir ? » est une question de **flux**, datée,
/// servie par le serveur. L'autre — « où en est la dette ? » — est un **état**,
/// et elle a quitté cet écran le 2026-09-10 pour le module Recouvrement, qui la
/// lit sur l'appareil.
///
/// Ce n'est pas un déplacement de confort. Le registre local voit les
/// encaissements non encore remontés, le serveur non : deux écrans de
/// recouvrement auraient donné deux chiffres sur les mêmes données, et celui
/// qui compose la file d'écritures est le seul à ne pas se tromper.
///
/// La page garde son chemin, son entrée de menu et sa permission : le profil
/// « pilotage sans accès aux créances » (`finance.stats.read` sans
/// `finance.charge.read`) y trouve toujours de quoi lire.
class FinanceStatsDashboardPage extends StatefulWidget {
  const FinanceStatsDashboardPage({super.key});

  @override
  State<FinanceStatsDashboardPage> createState() =>
      _FinanceStatsDashboardPageState();
}

class _FinanceStatsDashboardPageState extends State<FinanceStatsDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Un seul onglet, donc une seule lecture, et elle part au montage. Le
    // chargement paresseux qui existait ici n'avait de sens qu'avec deux
    // moitiés dont on ne lisait qu'une.
    context.read<FinanceTillBloc>().add(const FinanceTillRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPageBackground(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<FinanceTillBloc, FinanceTillState>(
            buildWhen: (prev, curr) => prev.till != curr.till,
            builder: (context, state) => FinanceStatsDashboardHeader(
              schoolYear: state.till?.context.schoolYear,
              l10n: l10n,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          const FinanceTillTab(),
        ],
      ),
    );
  }
}
