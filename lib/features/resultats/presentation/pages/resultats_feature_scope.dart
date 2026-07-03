import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/eleve_search_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/periodes_scolaires_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_classe_bloc.dart';

/// Portée BLoC de la feature résultats (AGENTS.md §11) : fournit les BLoCs de
/// lecture (vue classe, recherche élève, périodes) + le lecteur d'année courante
/// (cascade + academicYearId depuis le cache bootstrap), tous fermés en dispose.
/// La vue focus fournit son propre `ResultatFocusBloc` (patron « détail »).
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
  late final BootstrapCurrentYearBloc _bootstrapCurrentYearBloc;

  @override
  void initState() {
    super.initState();
    _resultatsClasseBloc = GetIt.instance<ResultatsClasseBloc>();
    _eleveSearchBloc = GetIt.instance<EleveSearchBloc>();
    _periodesScolairesBloc = GetIt.instance<PeriodesScolairesBloc>();
    _bootstrapCurrentYearBloc = GetIt.instance<BootstrapCurrentYearBloc>()
      ..add(
        const BootstrapContextLocalRequested(
          key: AppConstants.bootstrapPayloadKey,
        ),
      );
  }

  @override
  void dispose() {
    _resultatsClasseBloc.close();
    _eleveSearchBloc.close();
    _periodesScolairesBloc.close();
    _bootstrapCurrentYearBloc.close();
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
        BlocProvider<BootstrapCurrentYearBloc>.value(
          value: _bootstrapCurrentYearBloc,
        ),
      ],
      child: widget.child,
    );
  }
}
