import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
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
      ],
      child: widget.child,
    );
  }
}
