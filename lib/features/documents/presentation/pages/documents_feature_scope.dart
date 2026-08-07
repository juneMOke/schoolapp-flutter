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
/// global du `PullCoordinator` ne se déclenche qu'au RETOUR online — une
/// tablette démarrée déjà connectée ne tirerait jamais.
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
