import 'package:school_app_flutter/features/schedule/data/sync/time_grids_pull_handler.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_pull_handlers.dart';

/// Les flux que l'emploi du temps par classe re-tire à la demande (F5,
/// « Réessayer », après une publication, une version dépassée).
const Set<String> kClassTimetableResources = {
  kScheduleTimeGridsResource,
  'schedule_time_slots',
  kScheduleProgrammesResource,
  kScheduleTimetablesResource,
  kScheduleTimetableCellsResource,
};
