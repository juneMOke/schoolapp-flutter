import 'package:school_app_flutter/core/offline/resource_sync_signals.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_pull_repository.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_cours_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart';
import 'package:school_app_flutter/features/class_journal/data/repositories/journal_pull_repository.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/offline/schedule_pull_repository_impl.dart';

/// Ce qui périme une page du journal : une descente des entrées, de
/// l'emploi du temps (les lignes), des cours (une réaffectation), des
/// chapitres (les étiquettes), des disparitions — et la fin d'un envoi, où un
/// accusé pose « synchronisé » ou « à corriger » sur une séance.
class JournalChangeSource extends ResourceSyncSignals {
  const JournalChangeSource({
    required super.bus,
    required super.engine,
    required super.pull,
  }) : super(watched: watchedResources);

  static const Set<String> watchedResources = {
    kAcademicsJournalResourcePrefix,
    kScheduleTimeSlotsResource,
    kScheduleSessionsResource,
    kAcademicsCoursResourcePrefix,
    kAcademicsChapitresResourcePrefix,
    kTombstonesResource,
  };
}
