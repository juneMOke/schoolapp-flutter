import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/offline/sync_academics_pulls_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/course_bloc.dart';

/// Scope du module Cours : fournit le [CourseBloc] au sous-arbre et le ferme
/// à la sortie de la feature (cf. AGENTS.md §11 — FeatureScope).
///
/// Déclenche aussi, au montage, l'hydratation des caches Notes/Cours
/// ([SyncAcademicsPullsUseCase]) : le `PullCoordinator` ne se déclenche qu'au
/// RETOUR online — une tablette démarrée déjà connectée ne tirerait jamais.
/// **Best-effort** : lancé sans attendre, aucun échec ne remonte à l'UI (qui
/// lit le local de toute façon).
class CoursesFeatureScope extends StatefulWidget {
  final Widget child;

  const CoursesFeatureScope({super.key, required this.child});

  @override
  State<CoursesFeatureScope> createState() => _CoursesFeatureScopeState();
}

class _CoursesFeatureScopeState extends State<CoursesFeatureScope> {
  late final CourseBloc _courseBloc;

  @override
  void initState() {
    super.initState();
    _courseBloc = GetIt.instance<CourseBloc>();
    unawaited(GetIt.instance<SyncAcademicsPullsUseCase>()());
  }

  @override
  void dispose() {
    _courseBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CourseBloc>.value(
      value: _courseBloc,
      child: widget.child,
    );
  }
}
