import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/eleve_search_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/periodes_scolaires_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_classe_bloc.dart';

/// Portée BLoC de la feature résultats (AGENTS.md §11) : fournit les BLoCs de
/// lecture (vue classe, recherche élève, périodes) + le lecteur d'année
/// courante (cascade + academicYearId depuis le référentiel local) + les
/// classes (dropdown de la cascade), tous fermés en dispose. La vue focus
/// fournit son propre `ResultatFocusBloc` (patron « détail »).
class ResultatsFeatureScope extends StatefulWidget {
  final Widget child;

  const ResultatsFeatureScope({super.key, required this.child});

  @override
  State<ResultatsFeatureScope> createState() => _ResultatsFeatureScopeState();
}

class _ResultatsFeatureScopeState extends State<ResultatsFeatureScope> {
  late final ResultatsClasseBloc _resultatsClasseBloc;
  late final EleveSearchBloc _eleveSearchBloc;
  late final PeriodesScolairesBloc _periodesScolairesBloc;
  late final AcademicYearContextBloc _academicYearContextBloc;
  late final ClassroomOfflineBloc _classroomOfflineBloc;

  @override
  void initState() {
    super.initState();
    _resultatsClasseBloc = GetIt.instance<ResultatsClasseBloc>();
    _eleveSearchBloc = GetIt.instance<EleveSearchBloc>();
    _periodesScolairesBloc = GetIt.instance<PeriodesScolairesBloc>();
    _academicYearContextBloc = GetIt.instance<AcademicYearContextBloc>()
      ..add(const AcademicYearContextRequested());
    _classroomOfflineBloc = GetIt.instance<ClassroomOfflineBloc>();
  }

  @override
  void dispose() {
    _resultatsClasseBloc.close();
    _eleveSearchBloc.close();
    _periodesScolairesBloc.close();
    _academicYearContextBloc.close();
    _classroomOfflineBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ResultatsClasseBloc>.value(value: _resultatsClasseBloc),
        BlocProvider<EleveSearchBloc>.value(value: _eleveSearchBloc),
        BlocProvider<PeriodesScolairesBloc>.value(
          value: _periodesScolairesBloc,
        ),
        BlocProvider<AcademicYearContextBloc>.value(
          value: _academicYearContextBloc,
        ),
        BlocProvider<ClassroomOfflineBloc>.value(value: _classroomOfflineBloc),
      ],
      child: widget.child,
    );
  }
}
