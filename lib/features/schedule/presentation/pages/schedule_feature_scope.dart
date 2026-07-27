import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/offline/sync_academics_pulls_usecase.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/timetable_bloc.dart';

/// Scope du module Emploi du temps (cf. AGENTS.md §11 — FeatureScope) : fournit
/// le [TimetableBloc] (lecture) et le [AcademicYearContextBloc] (année
/// courante, nécessaire à `TimetableRequested`) au sous-arbre, et les ferme à
/// la sortie de la feature. Lecture seule : le `ScheduleEditBloc` n'est pas
/// monté ici.
class ScheduleFeatureScope extends StatefulWidget {
  final Widget child;

  const ScheduleFeatureScope({super.key, required this.child});

  @override
  State<ScheduleFeatureScope> createState() => _ScheduleFeatureScopeState();
}

class _ScheduleFeatureScopeState extends State<ScheduleFeatureScope> {
  late final TimetableBloc _timetableBloc;
  late final AcademicYearContextBloc _academicYearContextBloc;

  @override
  void initState() {
    super.initState();
    _timetableBloc = GetIt.instance<TimetableBloc>();
    _academicYearContextBloc = GetIt.instance<AcademicYearContextBloc>();
    // Hydratation best-effort des caches emploi du temps / cours (le
    // PullCoordinator ne se déclenche qu'au retour online).
    unawaited(GetIt.instance<SyncAcademicsPullsUseCase>()());
  }

  @override
  void dispose() {
    _timetableBloc.close();
    _academicYearContextBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TimetableBloc>.value(value: _timetableBloc),
        BlocProvider<AcademicYearContextBloc>.value(
          value: _academicYearContextBloc,
        ),
      ],
      child: widget.child,
    );
  }
}
