import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_previous_year_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';

class EnrollmentFeatureScope extends StatefulWidget {
  final Widget child;

  const EnrollmentFeatureScope({super.key, required this.child});

  @override
  State<EnrollmentFeatureScope> createState() => _EnrollmentFeatureScopeState();
}

class _EnrollmentFeatureScopeState extends State<EnrollmentFeatureScope> {
  late final EnrollmentBloc _enrollmentBloc;
  // Bloc offline UNIQUE du module (convergence) : brouillon par étape du wizard
  // + détail local + finalisation + pull des ressources de référence.
  late final EnrollmentOfflineBloc _enrollmentOfflineBloc;
  // Bloc DÉDIÉ du listing LOCAL (bascule dure 100 % local), séparé du convergé.
  late final EnrollmentLocalListBloc _enrollmentLocalListBloc;
  late final BootstrapCurrentYearBloc _bootstrapCurrentYearBloc;
  late final BootstrapPreviousYearBloc _bootstrapPreviousYearBloc;

  @override
  void initState() {
    super.initState();
    _enrollmentBloc = GetIt.instance<EnrollmentBloc>();
    _enrollmentOfflineBloc = GetIt.instance<EnrollmentOfflineBloc>();
    _enrollmentLocalListBloc = GetIt.instance<EnrollmentLocalListBloc>();
    _bootstrapCurrentYearBloc = GetIt.instance<BootstrapCurrentYearBloc>();
    _bootstrapPreviousYearBloc = GetIt.instance<BootstrapPreviousYearBloc>();
    // Rafraîchit les caches de référence Inscription (référentiel, cohorte
    // N-1, préinscriptions, delta) à l'entrée du module — silencieux et
    // best-effort, en complément du cycle global au retour online.
    _enrollmentOfflineBloc.add(const EnrollmentPullRequested());
  }

  @override
  void dispose() {
    _enrollmentBloc.close();
    _enrollmentOfflineBloc.close();
    _enrollmentLocalListBloc.close();
    _bootstrapCurrentYearBloc.close();
    _bootstrapPreviousYearBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EnrollmentBloc>.value(value: _enrollmentBloc),
        BlocProvider<EnrollmentOfflineBloc>.value(
          value: _enrollmentOfflineBloc,
        ),
        BlocProvider<EnrollmentLocalListBloc>.value(
          value: _enrollmentLocalListBloc,
        ),
        BlocProvider<BootstrapCurrentYearBloc>.value(
          value: _bootstrapCurrentYearBloc,
        ),
        BlocProvider<BootstrapPreviousYearBloc>.value(
          value: _bootstrapPreviousYearBloc,
        ),
      ],
      child: widget.child,
    );
  }
}
