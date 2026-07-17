import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/sync_enrollment_pulls_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/sync_finance_pulls_use_case.dart';

/// Scope BLoC dédié au module Finance.
///
/// Instancie ses propres instances de [EnrollmentLocalListBloc] (recherche
/// d'élèves **100 % locale**, offline-first) et de [BootstrapCurrentYearBloc]
/// via la factory GetIt — complètement isolées des instances gérées par
/// `EnrollmentFeatureScope`.
///
/// Déclenche aussi, au montage, le pull du grand-livre ([SyncFinancePullsUseCase])
/// **et** celui du module Inscription ([SyncEnrollmentPullsUseCase], qui hydrate
/// la cohorte et les dossiers locaux dont dépend la recherche de la Facturation)
/// — même rôle qu'au montage de l'Inscription. Le cycle global du
/// `PullCoordinator` ne se déclenche qu'au RETOUR online : une tablette démarrée
/// déjà connectée ne tirerait jamais. Or ouvrir la Facturation est précisément le
/// moment d'hydrater le cache, avant de partir encaisser hors-ligne.
/// **Best-effort** : lancés sans attendre, aucun échec ne remonte à l'UI (qui lit
/// le local de toute façon).
class FinanceFeatureScope extends StatefulWidget {
  final Widget child;

  const FinanceFeatureScope({super.key, required this.child});

  @override
  State<FinanceFeatureScope> createState() => _FinanceFeatureScopeState();
}

class _FinanceFeatureScopeState extends State<FinanceFeatureScope> {
  late final EnrollmentLocalListBloc _enrollmentLocalListBloc;
  late final BootstrapCurrentYearBloc _bootstrapCurrentYearBloc;

  @override
  void initState() {
    super.initState();
    _enrollmentLocalListBloc = GetIt.instance<EnrollmentLocalListBloc>();
    _bootstrapCurrentYearBloc = GetIt.instance<BootstrapCurrentYearBloc>();
    unawaited(GetIt.instance<SyncFinancePullsUseCase>()());
    unawaited(GetIt.instance<SyncEnrollmentPullsUseCase>()());
  }

  @override
  void dispose() {
    _enrollmentLocalListBloc.close();
    _bootstrapCurrentYearBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EnrollmentLocalListBloc>.value(
          value: _enrollmentLocalListBloc,
        ),
        BlocProvider<BootstrapCurrentYearBloc>.value(
          value: _bootstrapCurrentYearBloc,
        ),
      ],
      child: widget.child,
    );
  }
}
