import 'package:school_app_flutter/core/offline/resource_sync_signals.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_pull_repository.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_cours_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart';

/// Ce qui périme un écran du programme : une descente des chapitres, des
/// évaluations (leurs rattachements), des cours (une réaffectation), des
/// disparitions — et la fin d'un envoi, où un accusé pose « synchronisé » ou
/// « à corriger » sur une ligne.
class ProgrammeChangeSource extends ResourceSyncSignals {
  const ProgrammeChangeSource({
    required super.bus,
    required super.engine,
    required super.pull,
  }) : super(watched: watchedResources);

  static const Set<String> watchedResources = {
    kAcademicsChapitresResourcePrefix,
    kAcademicsEvaluationsResourcePrefix,
    kAcademicsCoursResourcePrefix,
    kTombstonesResource,
  };
}
