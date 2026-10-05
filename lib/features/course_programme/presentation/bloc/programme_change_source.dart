import 'dart:async';

import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_pull_repository.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_cours_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart';

/// Ce qui périme un écran du programme : une descente des chapitres, des
/// évaluations (leurs rattachements), des cours (une réaffectation), des
/// disparitions — et la fin d'un envoi, où un accusé pose « synchronisé » ou
/// « à corriger » sur une ligne.
class ProgrammeChangeSource {
  final PullCompletionBus? _bus;
  final SyncEngine? _engine;

  const ProgrammeChangeSource({PullCompletionBus? bus, SyncEngine? engine})
    : _bus = bus,
      _engine = engine;

  static const Set<String> watchedResources = {
    kAcademicsChapitresResourcePrefix,
    kAcademicsEvaluationsResourcePrefix,
    kAcademicsCoursResourcePrefix,
    kTombstonesResource,
  };

  /// Appelle [onChanged] à chaque signal ; rend la fonction qui désabonne.
  void Function() watch(void Function() onChanged) {
    final subscription = _bus?.stream
        .where((resources) => resources.any(watchedResources.contains))
        .listen((_) => onChanged());
    final removeFlushListener = _engine?.addFlushCompleteListener(onChanged);
    return () {
      unawaited(subscription?.cancel());
      removeFlushListener?.call();
    };
  }
}
