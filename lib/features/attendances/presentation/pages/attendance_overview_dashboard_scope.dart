import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_overview_bloc.dart';

/// Scope BLoC dédié au tableau de bord des présences (Disciplines).
/// Récupère le BLoC en factory depuis GetIt et le ferme dans [dispose].
class AttendanceOverviewDashboardScope extends StatefulWidget {
  final Widget child;

  const AttendanceOverviewDashboardScope({super.key, required this.child});

  @override
  State<AttendanceOverviewDashboardScope> createState() =>
      _AttendanceOverviewDashboardScopeState();
}

class _AttendanceOverviewDashboardScopeState
    extends State<AttendanceOverviewDashboardScope> {
  late final AttendanceOverviewBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<AttendanceOverviewBloc>();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AttendanceOverviewBloc>.value(
      value: _bloc,
      child: widget.child,
    );
  }
}
