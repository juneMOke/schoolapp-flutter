import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/school_calendar/data/local/calendar_event_dao.dart';
import 'package:school_app_flutter/features/school_calendar/data/local/calendar_reference_dao.dart';
import 'package:school_app_flutter/features/school_calendar/data/local/calendar_scope_options_dao.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope_options.dart';
import 'package:school_app_flutter/features/school_calendar/data/online/calendar_online_api.dart';
import 'package:school_app_flutter/features/school_calendar/data/sync/calendar_events_outbox_handler.dart';
import 'package:school_app_flutter/features/school_calendar/data/sync/calendar_pullers.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/repositories/school_calendar_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';

class SchoolCalendarRepositoryImpl implements SchoolCalendarRepository {
  final Database _db;
  final CalendarReferenceDao _reference;
  final CalendarEventDao _events;
  final CalendarOnlineApi _online;
  final CurrentUserContext _currentUser;
  final IdGenerator _ids;
  final PullCoordinator? _coordinator;
  final SyncEngine? _engine;
  final DateTime Function() _now;

  SchoolCalendarRepositoryImpl({
    required Database db,
    required CalendarOnlineApi online,
    required CurrentUserContext currentUser,
    required IdGenerator ids,
    PullCoordinator? coordinator,
    SyncEngine? engine,
    DateTime Function()? now,
  }) : _db = db,
       _reference = CalendarReferenceDao(db),
       _events = CalendarEventDao(db),
       _online = online,
       _currentUser = currentUser,
       _ids = ids,
       _coordinator = coordinator,
       _engine = engine,
       _now = now ?? DateTime.now;

  static const Set<String> resources = {
    kCalendarFrameworkResource,
    kCalendarCalendarsResource,
    kCalendarEventsResource,
  };

  String get _schoolId => _currentUser.schoolId ?? '';

  @override
  Future<CalendarLibrary> library() async => CalendarLibrary(
    calendars: await _reference.calendars(_schoolId),
    frameworks: await _reference.frameworks(_schoolId),
  );

  @override
  Future<List<SchoolEventRecord>> events(String calendarId) =>
      _events.eventsOf(calendarId);

  @override
  Future<CalendarScopeOptions> scopeOptions() =>
      CalendarScopeOptionsDao(_db).current(_schoolId);

  @override
  String newEventId() => _ids.newId();

  @override
  Future<Either<Failure, Unit>> saveEvent({
    required String calendarId,
    required CalendarElement element,
  }) => _write([
    SchoolEventRecord(
      element: element,
      calendarId: calendarId,
      clientUpdatedAtMs: 0,
    ),
  ]);

  @override
  Future<Either<Failure, Unit>> deleteEvent({
    required String calendarId,
    required CalendarElement element,
  }) => deleteEvents(calendarId: calendarId, elements: [element]);

  @override
  Future<Either<Failure, Unit>> deleteEvents({
    required String calendarId,
    required List<CalendarElement> elements,
  }) => _write([
    for (final element in elements)
      SchoolEventRecord(
        element: element,
        calendarId: calendarId,
        clientUpdatedAtMs: 0,
        deleted: true,
      ),
  ]);

  /// Le geste et son envoi dans **une** transaction : un geste gardé part
  /// toujours, un envoi ne part jamais sans son geste. Plusieurs lignes
  /// posées ensemble partent dans le même lot.
  Future<Either<Failure, Unit>> _write(List<SchoolEventRecord> records) async {
    final schoolId = _schoolId;
    if (schoolId.isEmpty) {
      return const Left(StorageFailure('Aucune école courante'));
    }
    try {
      final nowMs = _now().millisecondsSinceEpoch;
      await _db.transaction((txn) async {
        for (final record in records) {
          await CalendarEventDao.saveLocal(
            txn,
            record,
            schoolId: schoolId,
            nowMs: nowMs,
          );
        }
        await OutboxDao(txn).enqueue(
          calendarEventsOutboxEntry(schoolId: schoolId, createdAt: nowMs),
        );
      });
      final engine = _engine;
      if (engine != null) unawaited(engine.flush());
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<int> pendingCount(String calendarId) =>
      _events.pendingCount(_schoolId, calendarId: calendarId);

  @override
  Future<List<SchoolEventRecord>> takeSuperseded(String calendarId) =>
      _events.takeSuperseded(calendarId);

  @override
  Future<void> refresh() async {
    final coordinator = _coordinator;
    if (coordinator != null) await coordinator.pullSubset(resources);
  }

  @override
  Future<Either<Failure, List<({String yearLabel, FrameworkState framework})>>>
  creatableYears() async => (await _online.creatableYears()).map(
    (years) => [
      for (final y in years) (yearLabel: y.yearLabel, framework: y.framework),
    ],
  );

  @override
  Future<Either<Failure, SchoolCalendar>> create(String yearLabel) =>
      _keep(_online.create(id: _ids.newId(), yearLabel: yearLabel));

  @override
  Future<Either<Failure, SchoolCalendar>> duplicate({
    required SchoolCalendar source,
    required List<CalendarNature> natures,
  }) => _keep(
    _online.duplicate(
      sourceId: source.id,
      targetId: _ids.newId(),
      natures: natures,
    ),
  );

  /// Les dates des périodes changent à la publication (K4) : le socle des
  /// notes se retire aussi.
  @override
  Future<Either<Failure, SchoolCalendar>> publish(
    SchoolCalendar calendar,
  ) async {
    final result = await _keep(
      _online.publish(id: calendar.id, revision: calendar.revision),
    );
    final coordinator = _coordinator;
    if (result.isRight() && coordinator != null) {
      unawaited(
        coordinator.pullSubset({
          ...resourcesOf(SyncPlanKeys.academicsGradesReferential),
        }),
      );
    }
    return result;
  }

  @override
  Future<Either<Failure, PrintableDocument>> frameworkDocument(
    String yearLabel,
  ) => _online.frameworkDocument(yearLabel);

  /// Recopie l'en-tête rendu sans attendre le tirage, puis tire les flux :
  /// les événements dupliqués et les périodes changées descendent par eux.
  Future<Either<Failure, SchoolCalendar>> _keep(
    Future<Either<Failure, SchoolCalendar>> call,
  ) async {
    final result = await call;
    final calendar = result.toOption().toNullable();
    if (calendar != null && _schoolId.isNotEmpty) {
      await _db.insert(
        'school_calendars',
        CalendarReferenceDao.calendarRow(
          calendar,
          schoolId: _schoolId,
          nowMs: _now().millisecondsSinceEpoch,
        ),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      unawaited(refresh());
    }
    return result;
  }
}
