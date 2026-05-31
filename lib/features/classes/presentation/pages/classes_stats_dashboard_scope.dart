import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_stats_bloc.dart';

/// Scope BLoC dedie au dashboard des statistiques classes.
/// Cree et ferme proprement [ClassroomStatsBloc].
class ClassesStatsDashboardScope extends StatefulWidget {
  final Widget child;

  const ClassesStatsDashboardScope({super.key, required this.child});

  @override
  State<ClassesStatsDashboardScope> createState() =>
      _ClassesStatsDashboardScopeState();
}

class _ClassesStatsDashboardScopeState
    extends State<ClassesStatsDashboardScope> {
  late final ClassroomStatsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<ClassroomStatsBloc>();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClassroomStatsBloc>.value(
      value: _bloc,
      child: widget.child,
    );
  }
}
