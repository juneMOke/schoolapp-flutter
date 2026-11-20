import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope_options.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/repositories/school_calendar_repository.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

SchoolCalendar calendar(
  String year,
  CalendarStatus status,
  DateTime s,
  DateTime e,
) => SchoolCalendar(
  id: 'cal-$year',
  yearLabel: year,
  status: status,
  startDate: s,
  endDate: e,
  framework: FrameworkState.integrated,
  revision: 3,
);

CalendarElement item(
  String id,
  CalendarNature nature, {
  PeriodRhythm? rhythm,
  bool national = true,
  bool toVerify = false,
}) => CalendarElement(
  id: id,
  source: national ? CalendarSource.national : CalendarSource.school,
  nature: nature,
  title: id,
  startDate: d(2026, 6, 1),
  endDate: d(2026, 6, 2),
  rhythm: rhythm,
  toVerify: toVerify,
);

class FakeCalendarRepository implements SchoolCalendarRepository {
  final saved = <CalendarElement>[];
  final deleted = <CalendarElement>[];
  var stored = <SchoolEventRecord>[
    SchoolEventRecord(
      element: item(
        'reunion',
        CalendarNature.schoolLife,
        national: false,
        toVerify: true,
      ),
      calendarId: 'cal-2025-2026',
      clientUpdatedAtMs: 1,
    ),
  ];

  @override
  Future<CalendarLibrary> library() async => CalendarLibrary(
    calendars: [
      calendar(
        '2025-2026',
        CalendarStatus.published,
        d(2025, 9, 1),
        d(2026, 7, 3),
      ),
      calendar('2026-2027', CalendarStatus.draft, d(2026, 9, 7), d(2027, 7, 2)),
    ],
    frameworks: [
      NationalFramework(
        id: 'f',
        yearLabel: '2025-2026',
        version: 1,
        startDate: d(2025, 9, 1),
        endDate: d(2026, 7, 3),
        items: [
          item('p-s', CalendarNature.period, rhythm: PeriodRhythm.semester),
          item('p-t', CalendarNature.period, rhythm: PeriodRhythm.trimester),
          item('ferie', CalendarNature.publicHoliday),
        ],
      ),
    ],
  );

  @override
  Future<CalendarScopeOptions> scopeOptions() async =>
      const CalendarScopeOptions(
        cycles: [
          CalendarCycleOption(
            code: 'PRI',
            name: 'Primaire',
            rhythm: PeriodRhythm.trimester,
          ),
          CalendarCycleOption(
            code: 'SEC',
            name: 'Secondaire',
            rhythm: PeriodRhythm.semester,
          ),
          CalendarCycleOption(
            code: 'HUM',
            name: 'Humanités',
            rhythm: PeriodRhythm.semester,
          ),
        ],
      );

  @override
  Future<List<SchoolEventRecord>> events(String calendarId) async => [
    for (final e in stored)
      if (e.calendarId == calendarId) e,
  ];

  @override
  Future<Either<Failure, Unit>> saveEvent({
    required String calendarId,
    required CalendarElement element,
  }) async {
    saved.add(element);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteEvent({
    required String calendarId,
    required CalendarElement element,
  }) async {
    deleted.add(element);
    return const Right(unit);
  }

  @override
  String newEventId() => 'new';

  @override
  Future<int> pendingCount(String calendarId) async => 0;

  @override
  Future<List<SchoolEventRecord>> takeSuperseded(String calendarId) async =>
      const [];

  @override
  Future<void> refresh() async {}

  @override
  Future<Either<Failure, List<({String yearLabel, FrameworkState framework})>>>
  creatableYears() async => const Right([]);

  @override
  Future<Either<Failure, SchoolCalendar>> create(String yearLabel) async =>
      Right(
        calendar(
          yearLabel,
          CalendarStatus.draft,
          d(2027, 9, 6),
          d(2028, 7, 31),
        ),
      );

  @override
  Future<Either<Failure, SchoolCalendar>> duplicate({
    required SchoolCalendar source,
    required List<CalendarNature> natures,
  }) async => const Left(ServerFailure());

  @override
  Future<Either<Failure, SchoolCalendar>> publish(
    SchoolCalendar calendar,
  ) async => const Left(ServerFailure());
}
