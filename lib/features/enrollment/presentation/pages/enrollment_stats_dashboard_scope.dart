import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stats_bloc.dart';

/// Scope BLoC dédié au dashboard des statistiques d'inscriptions.
/// Crée et ferme proprement [EnrollmentStatsBloc].
class EnrollmentStatsDashboardScope extends StatefulWidget {
  final Widget child;

  const EnrollmentStatsDashboardScope({super.key, required this.child});

  @override
  State<EnrollmentStatsDashboardScope> createState() =>
      _EnrollmentStatsDashboardScopeState();
}

class _EnrollmentStatsDashboardScopeState
    extends State<EnrollmentStatsDashboardScope> {
  late final EnrollmentStatsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<EnrollmentStatsBloc>();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EnrollmentStatsBloc>.value(
      value: _bloc,
      child: widget.child,
    );
  }
}
