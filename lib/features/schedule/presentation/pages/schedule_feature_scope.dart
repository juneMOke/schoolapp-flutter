import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/timetable_bloc.dart';

/// Scope du module Emploi du temps (cf. AGENTS.md §11 — FeatureScope) : fournit
/// le [TimetableBloc] (lecture) et le [BootstrapCurrentYearBloc] (année courante,
/// nécessaire à `TimetableRequested`) au sous-arbre, et les ferme à la sortie de
/// la feature. Lecture seule : le `ScheduleEditBloc` n'est pas monté ici.
class ScheduleFeatureScope extends StatefulWidget {
  final Widget child;

  const ScheduleFeatureScope({super.key, required this.child});

  @override
  State<ScheduleFeatureScope> createState() => _ScheduleFeatureScopeState();
}

class _ScheduleFeatureScopeState extends State<ScheduleFeatureScope> {
  late final TimetableBloc _timetableBloc;
  late final BootstrapCurrentYearBloc _bootstrapCurrentYearBloc;

  @override
  void initState() {
    super.initState();
    _timetableBloc = GetIt.instance<TimetableBloc>();
    _bootstrapCurrentYearBloc = GetIt.instance<BootstrapCurrentYearBloc>();
  }

  @override
  void dispose() {
    _timetableBloc.close();
    _bootstrapCurrentYearBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TimetableBloc>.value(value: _timetableBloc),
        BlocProvider<BootstrapCurrentYearBloc>.value(
          value: _bootstrapCurrentYearBloc,
        ),
      ],
      child: widget.child,
    );
  }
}
