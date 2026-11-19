import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_grid.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Clé de routage du flux `schedule.time-grids`.
const String kScheduleTimeGridsResource = 'schedule_time_grids';

/// Une ligne du flux : la grille, son horloge, et sa disparition.
class PulledTimeGrid {
  final TimeGrid grid;
  final int? serverUpdatedAtMs;
  final bool deleted;

  const PulledTimeGrid(
    this.grid,
    this.serverUpdatedAtMs, {
    this.deleted = false,
  });

  static PulledTimeGrid parse(Object? raw) {
    final j = raw as Map<String, dynamic>;
    return PulledTimeGrid(
      TimeGrid(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        isDefault: j['isDefault'] == true,
        cycleCodes: [
          for (final code in (j['cycleCodes'] as List?) ?? const [])
            if (code is String && code.isNotEmpty) code,
        ],
        recess: MinuteRange.fromClocks(
          j['breakStart'] as String?,
          j['breakEnd'] as String?,
        ),
      ),
      EpochIsoHelper.tryToEpochMs(j['serverUpdatedAt']),
      deleted: j['deleted'] == true,
    );
  }
}

/// `ref_time_grids` : écrite par le flux, lue par l'emploi du temps.
class TimeGridDao {
  final DatabaseExecutor _db;

  const TimeGridDao(this._db);

  static const table = 'ref_time_grids';

  Future<int> apply(List<PulledTimeGrid> rows, int nowMs) async {
    if (rows.isEmpty) return 0;
    final batch = _db.batch();
    for (final row in rows) {
      if (row.deleted) {
        batch.delete(table, where: 'id = ?', whereArgs: [row.grid.id]);
        continue;
      }
      final recess = row.grid.recess;
      batch.insert(table, {
        'id': row.grid.id,
        'name': row.grid.name,
        'is_default': row.grid.isDefault ? 1 : 0,
        'cycle_codes': row.grid.cycleCodes.join(','),
        'break_start': recess == null ? null : _clock(recess.startMinute),
        'break_end': recess == null ? null : _clock(recess.endMinute),
        'server_updated_at': row.serverUpdatedAtMs,
        'synced_at': nowMs,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    return rows.length;
  }

  Future<Map<String, TimeGrid>> all() async => {
    for (final r in await _db.query(table))
      r['id']! as String: TimeGrid(
        id: r['id']! as String,
        name: r['name']! as String,
        isDefault: r['is_default'] == 1,
        cycleCodes: [
          for (final code in ((r['cycle_codes'] as String?) ?? '').split(','))
            if (code.isNotEmpty) code,
        ],
        recess: MinuteRange.fromClocks(
          r['break_start'] as String?,
          r['break_end'] as String?,
        ),
      ),
  };

  static String _clock(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';
}

/// Le [PullHandler] de `schedule.time-grids`, accordé par `schedule.read`.
class TimeGridsPullHandler implements PullHandler {
  final Dio _dio;
  final KeysetPullRunner _runner;
  final TimeGridDao _dao;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _requiredAuth;

  const TimeGridsPullHandler({
    required Dio dio,
    required KeysetPullRunner runner,
    required TimeGridDao dao,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> requiredAuth,
  }) : _dio = dio,
       _runner = runner,
       _dao = dao,
       _currentUser = currentUser,
       _requiredAuth = requiredAuth;

  @override
  String get resource => kScheduleTimeGridsResource;

  @override
  List<Perm> get requiredPermissions => const [Perm.scheduleRead];

  @override
  bool get isBaseline => false;

  Future<Either<Failure, KeysetPullResult>> run() {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) {
      return Future.value(const Left(ServerFailure('Aucune école courante')));
    }
    return _runner.run<PulledTimeGrid>(
      cursorKey: '$kScheduleTimeGridsResource@$schoolId',
      label: kScheduleTimeGridsResource,
      fetch: (cursor) async {
        final response = await _dio.get<Map<String, dynamic>>(
          AppConstants.syncScheduleTimeGridsEndpoint,
          queryParameters: {'cursor': ?cursor, 'limit': 200},
          options: Options(extra: _requiredAuth),
        );
        return ParsedKeysetPage.fromJson(response.data ?? const {}, (raw) {
          try {
            return PulledTimeGrid.parse(raw);
          } catch (_) {
            return null;
          }
        });
      },
      apply: (items, nowMs) => _dao.apply(items, nowMs),
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
