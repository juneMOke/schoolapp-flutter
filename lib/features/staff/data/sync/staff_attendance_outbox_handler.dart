import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_lock_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_sync_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_sync_api.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_outbox_dispatch.dart';

/// Handler d'outbox de l'agrégat `STAFF_ATTENDANCE` — un pointage.
///
/// **Deux attentes**, lues en local (`blocked` : ni tentative, ni poison) :
/// 1. la fiche de l'agent n'est pas encore connue du serveur ;
/// 2. une **réouverture** du jour attend son accusé — partir avant elle, ce
///    serait revenir en `DAY_LOCKED`, refus définitif, pour un pointage saisi
///    après avoir rouvert.
///
/// Une fiche absente du poste (purgée) rend le pointage sans objet.
class StaffAttendanceOutboxHandler implements OutboxSyncHandler {
  final StaffAttendanceSyncApi _api;
  final StaffAttendanceSyncDao _dao;
  final StaffAttendanceLockDao _locks;
  final StaffMemberDao _members;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const StaffAttendanceOutboxHandler({
    required StaffAttendanceSyncApi api,
    required StaffAttendanceSyncDao dao,
    required StaffAttendanceLockDao locks,
    required StaffMemberDao members,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _locks = locks,
       _members = members,
       _currentUser = currentUser,
       _extras = extras,
       _now = now;

  /// Le refus rangé quand la fiche de l'agent a disparu du poste.
  static const String memberGoneCode = 'STAFF_MEMBER_GONE';

  @override
  String get aggregateType => StaffAttendanceWriteDao.aggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final request = StaffOutboxDispatch.decode(
      entry.payload,
      StaffAttendanceSyncRequestDto.tryParse,
    );
    if (request == null) {
      return const OutboxDispatchResult.failed('Payload de pointage illisible');
    }
    final hold = outboxForeignSchoolHold(entry, _currentUser.schoolId);
    if (hold != null) return hold;
    final sent = request.staffAttendance;
    final schoolId = entry.schoolId ?? '';

    final member = await _members.find(sent.staffMemberId);
    if (member == null) {
      const reason = 'Agent inconnu sur le poste';
      await _dao.markRejected(
        sent.id,
        sentClientUpdatedAt: sent.clientUpdatedAt,
        code: memberGoneCode,
        reason: reason,
        nowMs: _now(),
      );
      return const OutboxDispatchResult.failed(reason);
    }
    if (member.row['version'] == null) {
      return const OutboxDispatchResult.blocked('Fiche pas encore accusée');
    }
    if (await _locks.hasPendingReopen(
      schoolId,
      sent.workDate,
      queuedBefore: entry.createdAt,
    )) {
      return const OutboxDispatchResult.blocked('Réouverture du jour en vol');
    }

    return StaffOutboxDispatch.push(
      send: () async {
        final ack = await _api.submitAttendance(_extras, request.toJson());
        await _dao.applyAck(
          ack.staffAttendance,
          sentClientUpdatedAt: sent.clientUpdatedAt,
          schoolId: schoolId,
          nowMs: _now(),
        );
      },
      reject: (failure) => _dao.markRejected(
        sent.id,
        sentClientUpdatedAt: sent.clientUpdatedAt,
        code: failure.storedCode,
        reason: failure.reason,
        nowMs: _now(),
      ),
    );
  }
}
