import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/offline/sync_academics_pulls_usecase.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/offline/schedule_pull_repository_impl.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/timetable_bloc.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/timetable_event.dart';

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
  StreamSubscription<Set<String>>? _pullSub;

  /// Ressources dont un rafraîchissement change la grille affichée : les
  /// séances (le contenu) et les créneaux (les lignes de la grille).
  static const Set<String> _watched = {
    kScheduleSessionsResource,
    kScheduleTimeSlotsResource,
  };

  @override
  void initState() {
    super.initState();
    _timetableBloc = GetIt.instance<TimetableBloc>();
    _academicYearContextBloc = GetIt.instance<AcademicYearContextBloc>();
    // Relit la grille quand un pull a effectivement rafraîchi le cache : sans
    // cet abonnement, un cache froid resterait affiché vide jusqu'à ce que
    // l'utilisateur sorte de la feature et y revienne (cf. PullCompletionBus).
    _listenPullCompletion();
    // Hydratation best-effort des caches emploi du temps / cours (le
    // cycle complet du coordinateur ne part qu'à l'ouverture de session et au
    // retour online, jamais au montage d'un écran). Passe PAR le coordinateur
    // depuis ADR-015 F6.
    unawaited(GetIt.instance<SyncAcademicsPullsUseCase>()());
  }

  /// Abonnement défensif : le bus est optionnel dans la DI (tests, socle
  /// offline non enregistré) — son absence ne doit pas casser le montage de la
  /// feature, qui reste fonctionnelle en lecture locale.
  void _listenPullCompletion() {
    if (!GetIt.instance.isRegistered<PullCompletionBus>()) return;
    _pullSub = GetIt.instance<PullCompletionBus>().stream.listen(
      (resources) {
        if (!mounted || resources.intersection(_watched).isEmpty) return;
        _timetableBloc.add(const TimetableRefreshRequested());
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    unawaited(_pullSub?.cancel());
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
