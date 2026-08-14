import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/sync_classroom_referential_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/sync_enrollment_pulls_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/sync_finance_pulls_use_case.dart';

/// Scope BLoC dédié au module Finance.
///
/// Instancie ses propres instances de [EnrollmentLocalListBloc] (recherche
/// d'élèves **100 % locale**, offline-first) et de [AcademicYearContextBloc]
/// via la factory GetIt — complètement isolées des instances gérées par
/// `EnrollmentFeatureScope`.
///
/// Déclenche aussi, au montage, le pull du grand-livre ([SyncFinancePullsUseCase]),
/// celui du module Inscription ([SyncEnrollmentPullsUseCase], qui hydrate
/// la cohorte et les dossiers locaux dont dépend la recherche de la Facturation)
/// **et** celui du référentiel Classe ([SyncClassroomReferentialUseCase], dont le
/// roster borne la recherche par classe du Contrôle des frais)
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
  late final AcademicYearContextBloc _academicYearContextBloc;

  @override
  void initState() {
    super.initState();
    _enrollmentLocalListBloc = GetIt.instance<EnrollmentLocalListBloc>();
    _academicYearContextBloc = GetIt.instance<AcademicYearContextBloc>();
    unawaited(GetIt.instance<SyncFinancePullsUseCase>()());
    unawaited(GetIt.instance<SyncEnrollmentPullsUseCase>()());
    // Référentiel Classe : le Contrôle des frais borne sa recherche à une
    // classe en lisant le roster local. Sans cette hydratation, l'écran
    // consommait une table que personne ne remplissait ici — le pull Classe
    // n'est déclenché qu'au montage de l'écran Classes ou au retour online —
    // et la recherche par classe remontait zéro élève, silencieusement.
    unawaited(GetIt.instance<SyncClassroomReferentialUseCase>()());
  }

  @override
  void dispose() {
    _enrollmentLocalListBloc.close();
    _academicYearContextBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EnrollmentLocalListBloc>.value(
          value: _enrollmentLocalListBloc,
        ),
        BlocProvider<AcademicYearContextBloc>.value(
          value: _academicYearContextBloc,
        ),
      ],
      child: widget.child,
    );
  }
}
