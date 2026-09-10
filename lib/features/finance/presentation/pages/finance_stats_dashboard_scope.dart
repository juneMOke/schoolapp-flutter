import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/exchange_rates_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_receipts_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_report_cubit.dart';

/// Scope BLoC du tableau de bord Finances — **la caisse**, et ses satellites.
///
/// Le bloc du recouvrement a quitté ce scope le 2026-09-10 avec son onglet : la
/// dette se lit désormais sur l'appareil, dans le module Recouvrement. Ce qui
/// reste vit ici plutôt que dans les widgets pour survivre aux reconstructions
/// — une attente imposée par un 429 doit tenir même quand la carte se démonte.
///
/// Tous sont fermés dans [dispose] — c'est la contrepartie du
/// `registerFactory`.
class FinanceStatsDashboardScope extends StatefulWidget {
  final Widget child;

  const FinanceStatsDashboardScope({super.key, required this.child});

  @override
  State<FinanceStatsDashboardScope> createState() =>
      _FinanceStatsDashboardScopeState();
}

class _FinanceStatsDashboardScopeState
    extends State<FinanceStatsDashboardScope> {
  late final FinanceTillBloc _tillBloc;

  /// Le second appel de la caisse — nominatif, paginé, et **sous une seconde
  /// permission**. Il vit ici plutôt que dans l'onglet pour survivre aux
  /// bascules d'onglet, comme les deux autres.
  late final FinanceTillReceiptsBloc _receiptsBloc;

  /// Le téléchargement du rapport. Ici plutôt que dans le bouton : une attente
  /// imposée par un 429 doit survivre au démontage de la carte — sinon un
  /// aller-retour d'onglet réarme un bouton que le serveur vient de refuser.
  late final FinanceTillReportCubit _reportCubit;

  @override
  void initState() {
    super.initState();
    _tillBloc = GetIt.instance<FinanceTillBloc>();
    _receiptsBloc = GetIt.instance<FinanceTillReceiptsBloc>();
    _reportCubit = GetIt.instance<FinanceTillReportCubit>();
  }

  @override
  void dispose() {
    _tillBloc.close();
    _receiptsBloc.close();
    _reportCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FinanceTillBloc>.value(value: _tillBloc),
        BlocProvider<FinanceTillReceiptsBloc>.value(value: _receiptsBloc),
        BlocProvider<FinanceTillReportCubit>.value(value: _reportCubit),
        // Le taux du jour, pour le bandeau de l'onglet Caisse.
        //
        // Ici et non dans l'onglet, bien que seul l'onglet Caisse l'affiche :
        // monté dans l'onglet, il serait détruit et relu à chaque bascule, et
        // son `loaded` repassant à faux ferait **clignoter le bandeau** à
        // chaque retour. Le prix est une lecture locale pour qui n'ouvre jamais
        // la caisse — pas un appel réseau, contrairement aux agrégats, dont la
        // paresse se justifie par le délai de guichet.
        //
        // `create` et non `.value` : celui-ci se ferme tout seul, n'ayant pas à
        // survivre à la page comme les trois autres.
        BlocProvider<ExchangeRatesCubit>(
          create: (_) => GetIt.instance<ExchangeRatesCubit>()..load(),
        ),
      ],
      child: widget.child,
    );
  }
}
