import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/exchange_rates_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_recovery_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_receipts_bloc.dart';

/// Scope BLoC du tableau de bord Finances — **un bloc par onglet**.
///
/// Deux blocs et non un : les deux onglets interrogent deux routes, et l'onglet
/// Caisse ne se charge qu'à sa première ouverture. Un bloc commun aurait appelé
/// les deux au montage, pour un écran dont on ne lit qu'une moitié.
///
/// Les deux sont fermés dans [dispose] — c'est la contrepartie du
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
  late final FinanceRecoveryBloc _recoveryBloc;
  late final FinanceTillBloc _tillBloc;

  /// Le second appel de la caisse — nominatif, paginé, et **sous une seconde
  /// permission**. Il vit ici plutôt que dans l'onglet pour survivre aux
  /// bascules d'onglet, comme les deux autres.
  late final FinanceTillReceiptsBloc _receiptsBloc;

  @override
  void initState() {
    super.initState();
    _recoveryBloc = GetIt.instance<FinanceRecoveryBloc>();
    _tillBloc = GetIt.instance<FinanceTillBloc>();
    _receiptsBloc = GetIt.instance<FinanceTillReceiptsBloc>();
  }

  @override
  void dispose() {
    _recoveryBloc.close();
    _tillBloc.close();
    _receiptsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FinanceRecoveryBloc>.value(value: _recoveryBloc),
        BlocProvider<FinanceTillBloc>.value(value: _tillBloc),
        BlocProvider<FinanceTillReceiptsBloc>.value(value: _receiptsBloc),
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
