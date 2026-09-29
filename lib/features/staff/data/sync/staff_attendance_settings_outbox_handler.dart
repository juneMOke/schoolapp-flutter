import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_settings_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_settings_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_sync_api.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_outbox_dispatch.dart';

/// Handler d'outbox de l'agrégat `STAFF_ATTENDANCE_SETTINGS` — le début des
/// cours et la tolérance d'une école, dernier écrit gagne.
class StaffAttendanceSettingsOutboxHandler implements OutboxSyncHandler {
  final StaffAttendanceSyncApi _api;
  final StaffAttendanceSettingsDao _dao;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;

  const StaffAttendanceSettingsOutboxHandler({
    required StaffAttendanceSyncApi api,
    required StaffAttendanceSettingsDao dao,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
  }) : _api = api,
       _dao = dao,
       _currentUser = currentUser,
       _extras = extras;

  @override
  String get aggregateType => StaffAttendanceSettingsDao.aggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final request = StaffOutboxDispatch.decode(
      entry.payload,
      StaffAttendanceSettingsRequestDto.tryParse,
    );
    if (request == null) {
      return const OutboxDispatchResult.failed('Payload de réglages illisible');
    }
    final hold = outboxForeignSchoolHold(entry, _currentUser.schoolId);
    if (hold != null) return hold;
    final schoolId = entry.schoolId ?? '';

    return StaffOutboxDispatch.push(
      send: () async {
        await _api.putSettings(_extras, request.toJson());
        await _dao.settle(
          schoolId,
          sentClientUpdatedAt: request.clientUpdatedAt,
          failed: false,
        );
      },
      reject: (failure) async {
        await _dao.settle(
          schoolId,
          sentClientUpdatedAt: request.clientUpdatedAt,
          failed: true,
          code: failure.storedCode,
          reason: failure.reason,
        );
        return true;
      },
    );
  }
}
