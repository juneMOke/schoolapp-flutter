import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/school_calendar/data/local/calendar_event_dao.dart';
import 'package:school_app_flutter/features/school_calendar/data/local/calendar_reference_dao.dart';
import 'package:school_app_flutter/features/school_calendar/data/wire/calendar_wire.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';

/// Clés de routage des trois flux du calendrier côté client.
const String kCalendarFrameworkResource = 'calendar_framework';
const String kCalendarCalendarsResource = 'calendar_calendars';
const String kCalendarEventsResource = 'calendar_events';

/// Une page d'un flux du calendrier : une ligne illisible est sautée et
/// comptée, la page reste lisible.
class CalendarPageDto<T> extends ParsedKeysetPage<T> {
  CalendarPageDto(ParsedKeysetPage<T> parsed)
    : super(items: parsed.items, page: parsed.page, skipped: parsed.skipped);

  static CalendarPageDto<T> parse<T>(
    Map<String, dynamic> json,
    T Function(Object? raw) read,
  ) => CalendarPageDto(
    ParsedKeysetPage.fromJson(json, (raw) {
      try {
        return read(raw);
      } catch (_) {
        return null;
      }
    }),
  );
}

/// Ce qui distingue les trois flux : leur ressource, leur route, leur
/// lecture et leur écriture locale.
class CalendarFeed<T> {
  final String resource;
  final String endpoint;
  final T Function(Object? raw) read;
  final Future<int> Function(List<T> items, String schoolId, int nowMs) apply;

  const CalendarFeed({
    required this.resource,
    required this.endpoint,
    required this.read,
    required this.apply,
  });

  static CalendarFeed<Object> framework(CalendarReferenceDao dao) =>
      CalendarFeed(
        resource: kCalendarFrameworkResource,
        endpoint: AppConstants.syncCalendarFrameworkEndpoint,
        read: CalendarWire.frameworkFromJson,
        apply: (items, schoolId, nowMs) =>
            dao.applyFrameworks(items.cast(), schoolId: schoolId, nowMs: nowMs),
      );

  static CalendarFeed<Object> calendars(CalendarReferenceDao dao) =>
      CalendarFeed(
        resource: kCalendarCalendarsResource,
        endpoint: AppConstants.syncCalendarCalendarsEndpoint,
        read: CalendarWire.calendarFromJson,
        apply: (items, schoolId, nowMs) =>
            dao.applyCalendars(items.cast(), schoolId: schoolId, nowMs: nowMs),
      );

  /// [onPeriodsMoved] : un remplacement de période descendu (posé, modifié
  /// ou retiré par un autre appareil) a pu réécrire les dates des périodes,
  /// qui descendent par le référentiel des notes.
  static CalendarFeed<Object> events(
    CalendarEventDao dao, {
    void Function()? onPeriodsMoved,
  }) => CalendarFeed(
    resource: kCalendarEventsResource,
    endpoint: AppConstants.syncCalendarEventsEndpoint,
    read: CalendarWire.eventFromJson,
    apply: (items, schoolId, nowMs) async {
      final rows = items.cast<PulledEvent>();
      final applied = await dao.applyPulled(
        rows,
        schoolId: schoolId,
        nowMs: nowMs,
      );
      if (rows.any(
        (r) =>
            r.record.element.nature == CalendarNature.period &&
            r.record.element.isReplacement,
      )) {
        onPeriodsMoved?.call();
      }
      return applied;
    },
  );
}

/// Le [PullHandler] d'un flux du calendrier, accordé par `calendar.read`.
/// Curseur scopé par école : une tablette réaffectée ne reprend pas la
/// seconde école là où la première s'était arrêtée.
class CalendarPullHandler implements PullHandler {
  final CalendarFeed<Object> _feed;
  final Dio _dio;
  final KeysetPullRunner _runner;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _requiredAuth;

  const CalendarPullHandler({
    required CalendarFeed<Object> feed,
    required Dio dio,
    required KeysetPullRunner runner,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> requiredAuth,
  }) : _feed = feed,
       _dio = dio,
       _runner = runner,
       _currentUser = currentUser,
       _requiredAuth = requiredAuth;

  static const int pageLimit = 500;

  static String cursorKey(String resource, String schoolId) =>
      '$resource@$schoolId';

  @override
  String get resource => _feed.resource;

  @override
  List<Perm> get requiredPermissions => const [Perm.calendarRead];

  @override
  bool get isBaseline => false;

  Future<Either<Failure, KeysetPullResult>> run() async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) {
      return const Left(ServerFailure('Aucune école courante'));
    }
    return _runner.run<Object>(
      cursorKey: cursorKey(_feed.resource, schoolId),
      label: _feed.resource,
      fetch: _fetch,
      apply: (items, nowMs) => _feed.apply(items, schoolId, nowMs),
    );
  }

  /// Un 304 remonte en `DioException`, comme le lit `KeysetPullRunner`.
  Future<CalendarPageDto<Object>> _fetch(String? cursor) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _feed.endpoint,
      queryParameters: {'cursor': ?cursor, 'limit': pageLimit},
      options: Options(extra: _requiredAuth),
    );
    return CalendarPageDto.parse(response.data ?? const {}, _feed.read);
  }

  @override
  Future<PullOutcome> pull() async {
    final result = await run();
    return result.fold(
      (failure) => PullOutcome.error(failure.toString()),
      (outcome) => outcome.notModified
          ? const PullOutcome.notModified()
          : PullOutcome.updated(
              upserted: outcome.upserted,
              serverTimeMs: outcome.serverTimeMs,
            ),
    );
  }
}
