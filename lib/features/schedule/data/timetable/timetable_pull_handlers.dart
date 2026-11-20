import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_dao.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_wire.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';

/// Clés de routage des flux de l'emploi du temps par classe.
const String kScheduleProgrammesResource = 'schedule_programmes';
const String kScheduleTimetablesResource = 'schedule_timetables';
const String kScheduleTimetableCellsResource = 'schedule_timetable_cells';

/// Un flux keyset de l'emploi du temps : en-têtes ou cases, sous
/// `schedule.read` — le serveur ne sert les brouillons qu'à `schedule.write`
/// (A17). Curseur scopé par école.
class TimetableFeedPullHandler<T> implements PullHandler {
  @override
  final String resource;
  final String _endpoint;
  final PulledTimetableRow<T> Function(Object? raw) _read;
  final Future<int> Function(List<PulledTimetableRow<T>> rows, int nowMs)
  _apply;
  final Dio _dio;
  final KeysetPullRunner _runner;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _requiredAuth;

  const TimetableFeedPullHandler({
    required this.resource,
    required String endpoint,
    required PulledTimetableRow<T> Function(Object? raw) read,
    required Future<int> Function(List<PulledTimetableRow<T>> rows, int nowMs)
    apply,
    required Dio dio,
    required KeysetPullRunner runner,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> requiredAuth,
  }) : _endpoint = endpoint,
       _read = read,
       _apply = apply,
       _dio = dio,
       _runner = runner,
       _currentUser = currentUser,
       _requiredAuth = requiredAuth;

  static TimetableFeedPullHandler<ClassTimetableHeader> headers(
    TimetableDao dao,
    Dio dio,
    KeysetPullRunner runner,
    CurrentUserContext user,
    Map<String, dynamic> auth,
  ) => TimetableFeedPullHandler<ClassTimetableHeader>(
    resource: kScheduleTimetablesResource,
    endpoint: AppConstants.syncScheduleTimetablesEndpoint,
    read: TimetableWire.header,
    apply: dao.applyHeaders,
    dio: dio,
    runner: runner,
    currentUser: user,
    requiredAuth: auth,
  );

  static TimetableFeedPullHandler<ClassTimetableCell> cells(
    TimetableDao dao,
    Dio dio,
    KeysetPullRunner runner,
    CurrentUserContext user,
    Map<String, dynamic> auth,
  ) => TimetableFeedPullHandler<ClassTimetableCell>(
    resource: kScheduleTimetableCellsResource,
    endpoint: AppConstants.syncScheduleTimetableCellsEndpoint,
    read: TimetableWire.cell,
    apply: dao.applyCells,
    dio: dio,
    runner: runner,
    currentUser: user,
    requiredAuth: auth,
  );

  @override
  List<Perm> get requiredPermissions => const [Perm.scheduleRead];

  @override
  bool get isBaseline => false;

  Future<Either<Failure, KeysetPullResult>> run() {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) {
      return Future.value(const Left(ServerFailure('Aucune école courante')));
    }
    return _runner.run<PulledTimetableRow<T>>(
      cursorKey: '$resource@$schoolId',
      label: resource,
      fetch: (cursor) async {
        final response = await _dio.get<Map<String, dynamic>>(
          _endpoint,
          queryParameters: {'cursor': ?cursor, 'limit': 1000},
          options: Options(extra: _requiredAuth),
        );
        return ParsedKeysetPage.fromJson(response.data ?? const {}, (raw) {
          try {
            return _read(raw);
          } catch (_) {
            return null;
          }
        });
      },
      apply: _apply,
    );
  }

  @override
  Future<PullOutcome> pull() async => (await run()).fold(
    (failure) => PullOutcome.error(failure.toString()),
    (o) => o.notModified
        ? const PullOutcome.notModified()
        : PullOutcome.updated(
            upserted: o.upserted,
            serverTimeMs: o.serverTimeMs,
          ),
  );
}

/// Le bundle `schedule.programmes` (ETag, remplacé en entier) sous
/// `schedule.write` : un changement de barème ne touche pas la ligne du cours,
/// un keyset ne le ferait pas redescendre.
class ProgrammesPullHandler implements PullHandler {
  final Dio _dio;
  final TimetableDao _dao;
  final SyncMetaDao _meta;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _requiredAuth;
  final int Function() _now;

  ProgrammesPullHandler({
    required Dio dio,
    required TimetableDao dao,
    required SyncMetaDao meta,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> requiredAuth,
    int Function()? now,
  }) : _dio = dio,
       _dao = dao,
       _meta = meta,
       _currentUser = currentUser,
       _requiredAuth = requiredAuth,
       _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  @override
  String get resource => kScheduleProgrammesResource;

  @override
  List<Perm> get requiredPermissions => const [Perm.scheduleWrite];

  @override
  bool get isBaseline => false;

  @override
  Future<PullOutcome> pull() async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) {
      return const PullOutcome.error('Aucune école courante');
    }
    final key = '$kScheduleProgrammesResource@$schoolId';
    final etag = await _meta.getCursor(key);
    final nowMs = _now();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        AppConstants.syncScheduleProgrammesEndpoint,
        options: Options(
          extra: _requiredAuth,
          headers: {'If-None-Match': ?etag},
        ),
      );
      // Une ligne illisible est sautée, pas tout le programme de l'école.
      final items = [
        for (final raw in (response.data?['items'] as List?) ?? const [])
          ?_courseOrNull(raw),
      ];
      final applied = await _dao.replaceProgrammes(items, nowMs);
      await _meta.setCursor(
        key,
        cursor: response.headers.value('etag') ?? etag,
        syncedAt: nowMs,
      );
      return PullOutcome.updated(upserted: applied, serverTimeMs: nowMs);
    } on DioException catch (e) {
      if (e.response?.statusCode == 304) {
        await _meta.setCursor(key, cursor: etag, syncedAt: nowMs);
        return const PullOutcome.notModified();
      }
      return PullOutcome.error(e.message ?? e.toString());
    } catch (e) {
      return PullOutcome.error(e.toString());
    }
  }

  static TimetableCourse? _courseOrNull(Object? raw) {
    try {
      return TimetableWire.course(raw);
    } on Object {
      return null;
    }
  }
}
