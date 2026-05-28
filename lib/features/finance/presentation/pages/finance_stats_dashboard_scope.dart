import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_stats_bloc.dart';

/// Scope BLoC dedie au dashboard des statistiques finance.
class FinanceStatsDashboardScope extends StatefulWidget {
  final Widget child;

  const FinanceStatsDashboardScope({super.key, required this.child});

  @override
  State<FinanceStatsDashboardScope> createState() =>
      _FinanceStatsDashboardScopeState();
}

class _FinanceStatsDashboardScopeState
    extends State<FinanceStatsDashboardScope> {
  late final FinanceStatsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<FinanceStatsBloc>();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FinanceStatsBloc>.value(
      value: _bloc,
      child: widget.child,
    );
  }
}
