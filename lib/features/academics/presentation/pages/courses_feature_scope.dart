import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_cours_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/grades_referential_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/offline/sync_academics_pulls_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/course_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/course_event.dart';

/// Scope du module Cours : fournit le [CourseBloc] au sous-arbre et le ferme
/// à la sortie de la feature (cf. AGENTS.md §11 — FeatureScope).
///
/// Déclenche aussi, au montage, l'hydratation des caches Notes/Cours
/// ([SyncAcademicsPullsUseCase]) : le `PullCoordinator` ne se déclenche qu'au
/// cycle COMPLET du coordinateur — qui part à l'ouverture de session et au
/// retour online, mais pas au montage d'un écran. Les deux déclencheurs sont
/// nécessaires : sans celui-ci, ouvrir « Mes cours » en cours de session
/// n'hydraterait rien. Ce pull passe désormais PAR le coordinateur (ADR-015 F6).
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
  StreamSubscription<Set<String>>? _pullSub;

  /// « Mes cours » est une jointure `ref_cours` × bundle `grades-referential`
  /// (la branche vient du bundle) : un cours sans sa ligne de barème est exclu
  /// de la liste. Les deux ressources doivent donc réveiller l'écran.
  static const Set<String> _watched = {
    kAcademicsCoursResourcePrefix,
    kGradesReferentialResource,
  };

  @override
  void initState() {
    super.initState();
    _courseBloc = GetIt.instance<CourseBloc>();
    _listenPullCompletion();
    unawaited(GetIt.instance<SyncAcademicsPullsUseCase>()());
  }

  /// Abonnement défensif : bus optionnel dans la DI (tests, socle offline non
  /// enregistré) — son absence laisse la feature fonctionnelle en lecture
  /// locale.
  void _listenPullCompletion() {
    if (!GetIt.instance.isRegistered<PullCompletionBus>()) return;
    _pullSub = GetIt.instance<PullCompletionBus>().stream.listen(
      (resources) {
        if (!mounted || resources.intersection(_watched).isEmpty) return;
        _courseBloc.add(const MyCoursesRefreshRequested());
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    unawaited(_pullSub?.cancel());
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
