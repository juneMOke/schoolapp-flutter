import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_lock_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_sync_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_lock_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_sync_api.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_outbox_dispatch.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_work_calendar.dart';

/// Handler d'outbox de l'agrégat `STAFF_ATTENDANCE_GESTURE` — valider ou
/// rouvrir un jour, clore un mois.
///
/// **L'ordre est tenu ici**, le moteur d'outbox n'en garantissant aucun :
/// 1. un geste attend ses **aînés** encore en file sur la même période ;
/// 2. une validation (ou une clôture) attend les **pointages** de sa période
///    encore en file, sinon ils reviendraient `DAY_LOCKED`.
///
/// **Sortie de secours** : un pointage qui ne partira jamais ne retient pas
/// la validation — refusé (il n'est plus en file), ou attendant une fiche
/// d'agent elle-même refusée ou disparue.
class StaffAttendanceGestureOutboxHandler implements OutboxSyncHandler {
  final StaffAttendanceSyncApi _api;
  final StaffAttendanceLockDao _locks;
  final StaffAttendanceDao _records;
  final StaffAttendanceSyncDao _recordSync;
  final StaffMemberDao _members;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const StaffAttendanceGestureOutboxHandler({
    required StaffAttendanceSyncApi api,
    required StaffAttendanceLockDao locks,
    required StaffAttendanceDao records,
    required StaffAttendanceSyncDao recordSync,
    required StaffMemberDao members,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _locks = locks,
       _records = records,
       _recordSync = recordSync,
       _members = members,
       _currentUser = currentUser,
       _extras = extras,
       _now = now;

  @override
  String get aggregateType => StaffAttendanceLockDao.gestureAggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final request = StaffOutboxDispatch.decode(
      entry.payload,
      StaffAttendanceGestureRequestDto.tryParse,
    );
    final gesture = StaffAttendanceGesture.fromWire(request?.gesture);
    if (request == null || gesture == null) {
      return const OutboxDispatchResult.failed('Payload de geste illisible');
    }
    final hold = outboxForeignSchoolHold(entry, _currentUser.schoolId);
    if (hold != null) return hold;
    final schoolId = entry.schoolId ?? '';
    final (from, to) = _periodOf(gesture, request.date);

    if (await _locks.hasOlderPendingGesture(
      schoolId,
      gestureId: request.gestureId,
      createdAt: entry.createdAt,
      from: from,
      to: to,
    )) {
      return const OutboxDispatchResult.blocked('Un geste plus ancien attend');
    }
    if (gesture.locks &&
        await _hasRecordsToWaitFor(schoolId, from, to, entry.createdAt)) {
      return const OutboxDispatchResult.blocked(
        'Pointages de la période en vol',
      );
    }

    return StaffOutboxDispatch.push(
      send: () async {
        final state = await _api.submitGesture(_extras, request.toJson());
        await _locks.applyServer([state], schoolId: schoolId, nowMs: _now());
        await _locks.markGesture(request.gestureId, StaffSyncState.synced);
        if (gesture == StaffAttendanceGesture.reopenDay) {
          await _recordSync.requeueDayLocked(
            schoolId,
            request.date,
            nowMs: _now(),
          );
        }
      },
      reject: (failure) async {
        await _locks.markGesture(
          request.gestureId,
          StaffSyncState.failed,
          code: failure.storedCode,
          reason: failure.reason,
        );
        return true;
      },
    );
  }

  /// Le jour, ou tout le mois (ses jours et sa clôture).
  static (String, String) _periodOf(
    StaffAttendanceGesture gesture,
    String date,
  ) {
    if (gesture.kind == StaffAttendanceLockKind.day) return (date, date);
    final days = StaffWorkCalendar.daysOf(StaffWorkCalendar.monthOf(date));
    return (days.first, days.last);
  }

  /// Un pointage de la période partira-t-il encore ? Seuls ceux-là retiennent
  /// le geste ; un pointage dont la fiche est refusée ou disparue ne partira
  /// jamais.
  Future<bool> _hasRecordsToWaitFor(
    String schoolId,
    String from,
    String to,
    int queuedBefore,
  ) async {
    final pending = await _records.pendingIn(
      schoolId,
      from: from,
      to: to,
      queuedBefore: queuedBefore,
    );
    final byMember = <String, bool>{};
    for (final record in pending) {
      final memberId = record.row['staff_member_id']! as String;
      final alive = byMember[memberId] ??= await _memberCanSync(memberId);
      if (alive) return true;
    }
    return false;
  }

  Future<bool> _memberCanSync(String memberId) async {
    final member = await _members.find(memberId);
    return member != null && member.syncStatus != StaffSyncState.failed.dbValue;
  }
}
