import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/sync_enrollment_pulls_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';

/// Scope BLoC du module Documents.
///
/// Même composition que `FinanceFeatureScope` — la recherche d'élève est la
/// même brique, 100 % locale — avec ses **propres** instances résolues par la
/// factory GetIt, isolées de celles de la Facturation et de l'Inscription : deux
/// écrans ouverts sur des recherches différentes ne doivent pas se marcher
/// dessus.
///
/// Déclenche au montage le pull du module Inscription, qui hydrate les dossiers
/// locaux dont dépend la recherche. **Best-effort** : lancé sans attendre,
/// aucun échec ne remonte à l'UI, qui lit le local de toute façon. Le cycle
/// global du `PullCoordinator` ne se déclenche qu'à l'ouverture de session et au
/// cycle COMPLET du coordinateur — qui part à l'ouverture de session et au
/// retour online, mais pas au montage d'un écran. Ce pull passe désormais PAR le
/// coordinateur (ADR-015 F6), donc filtré par les droits comme tous les autres
/// de la journée.
///
/// ⚠️ **Depuis le repli ADR-015 F6, ce pull passe par le `PullCoordinator` et
/// est donc filtré par les permissions de la session** : `enrollment.read`
/// devient exigible pour que la recherche d'élève trouve quelque chose, là où
/// cet écran tirait jusqu'ici sans aucun filtre. Tous les gabarits de rôle par
/// défaut porteurs d'`editique.read` détiennent aussi `enrollment.read` (cf.
/// `role_journeys_test.dart`) ; un rôle **personnalisé** qui n'aurait que le
/// premier verra sa recherche rester vide, ce que `PullRunReport.forbidden`
/// est seul à dire.
class DocumentsFeatureScope extends StatefulWidget {
  final Widget child;

  const DocumentsFeatureScope({super.key, required this.child});

  @override
  State<DocumentsFeatureScope> createState() => _DocumentsFeatureScopeState();
}

class _DocumentsFeatureScopeState extends State<DocumentsFeatureScope> {
  late final EnrollmentLocalListBloc _enrollmentLocalListBloc;
  late final AcademicYearContextBloc _academicYearContextBloc;

  @override
  void initState() {
    super.initState();
    _enrollmentLocalListBloc = GetIt.instance<EnrollmentLocalListBloc>();
    _academicYearContextBloc = GetIt.instance<AcademicYearContextBloc>();
    unawaited(GetIt.instance<SyncEnrollmentPullsUseCase>()());
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
