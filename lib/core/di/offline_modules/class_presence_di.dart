import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/presence/data/presence_schedule_reader.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_draft_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_day_writer.dart';
import 'package:school_app_flutter/features/attendances/data/repository/register/class_presence_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/register/class_presence_repository.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/register/class_presence_use_cases.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Le registre d'appel d'une classe (Présences des élèves v2). Posé après
/// `registerClassroomAttendanceOffline`, dont il réutilise le stockage de
/// l'appel, le roster et la file d'envoi.
void registerClassPresence(GetIt getIt) {
  getIt.registerLazySingleton<AttendanceDraftLocalDataSource>(
    () => AttendanceDraftLocalDataSource(getIt<Database>()),
  );
  getIt.registerLazySingleton<AttendanceClosureLocalDataSource>(
    () => AttendanceClosureLocalDataSource(getIt<Database>()),
  );
  getIt.registerLazySingleton<PresenceScheduleReader>(
    () => PresenceScheduleReader(getIt<Database>()),
  );
  getIt.registerLazySingleton<AttendanceDayWriter>(
    () => AttendanceDayWriter(
      localDataSource: getIt<AttendanceLocalDataSource>(),
      rosterDataSource: getIt<ClassroomLocalDataSource>(),
      idGenerator: getIt<IdGenerator>(),
      currentUser: getIt<CurrentUserContext>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  getIt.registerLazySingleton<ClassPresenceRepository>(
    () => ClassPresenceRepositoryImpl(
      sessions: getIt<AttendanceLocalDataSource>(),
      drafts: getIt<AttendanceDraftLocalDataSource>(),
      closures: getIt<AttendanceClosureLocalDataSource>(),
      roster: getIt<ClassroomLocalDataSource>(),
      scheduleReader: getIt<PresenceScheduleReader>(),
      outbox: OutboxDao(getIt<Database>()),
      writer: getIt<AttendanceDayWriter>(),
      currentUser: getIt<CurrentUserContext>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );

  getIt.registerFactory(
    () => LoadClassPresenceDayUseCase(getIt<ClassPresenceRepository>()),
  );
  getIt.registerFactory(
    () => SaveClassPresenceMarksUseCase(getIt<ClassPresenceRepository>()),
  );
  getIt.registerFactory(
    () => ValidateClassPresenceDayUseCase(getIt<ClassPresenceRepository>()),
  );
  getIt.registerFactory(
    () => ReopenClassPresenceDayUseCase(getIt<ClassPresenceRepository>()),
  );
  getIt.registerFactory(
    () => RetryClassPresenceDayUseCase(getIt<ClassPresenceRepository>()),
  );
}
