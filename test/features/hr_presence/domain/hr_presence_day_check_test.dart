import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_justification.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/hr_presence/domain/services/hr_presence_day_check.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';

/// La fiche lit le serveur, la correction part de la tablette : on ne corrige
/// qu'une ligne que les deux connaissent pareil, ou que la tablette a écrite.
void main() {
  HrAttendanceDay server({
    PresenceStatus status = PresenceStatus.late,
    String? arrival = '07:52',
    int lateMinutes = 12,
    StaffAbsenceReason? reason,
  }) => HrAttendanceDay(
    date: '2026-09-28',
    status: status,
    arrival: arrival,
    lateMinutes: lateMinutes,
    workedMinutes: 0,
    reason: reason,
    future: false,
  );

  StaffAttendanceRecord local({
    PresenceStatus status = PresenceStatus.late,
    String arrival = '07:52',
    int lateMinutes = 12,
    StaffAbsenceReason? reason,
    RecordSyncState sync = RecordSyncState.synced,
  }) => StaffAttendanceRecord(
    id: 'r-1',
    staffMemberId: 'a-1',
    workDate: '2026-09-28',
    status: status,
    arrival: ClockTime.tryParse(arrival),
    lateMinutes: lateMinutes,
    justification: reason == null
        ? null
        : PresenceJustification(reason: reason),
    syncState: sync,
  );

  HrPresenceDayAgreement check(HrAttendanceDay s, StaffAttendanceRecord? l) =>
      HrPresenceDayCheck.of(server: s, local: l);

  test('la même ligne des deux côtés : corrigeable', () {
    expect(check(server(), local()), HrPresenceDayAgreement.same);
    expect(check(server(), local()).editable, isTrue);
  });

  test('ni l\'un ni l\'autre n\'a pointé : corrigeable, rien à écraser', () {
    expect(
      check(
        server(status: PresenceStatus.none, arrival: null, lateMinutes: 0),
        null,
      ),
      HrPresenceDayAgreement.same,
    );
  });

  test('le serveur a pointé, la tablette n\'a rien : lecture seule', () {
    final agreement = check(server(), null);
    expect(agreement, HrPresenceDayAgreement.missing);
    expect(agreement.editable, isFalse);
  });

  test('une ligne reçue qui diffère du serveur : lecture seule', () {
    expect(
      check(
        server(),
        local(arrival: '07:40', lateMinutes: 0, status: PresenceStatus.present),
      ),
      HrPresenceDayAgreement.divergent,
    );
    expect(
      check(
        server(
          status: PresenceStatus.absent,
          arrival: null,
          lateMinutes: 0,
          reason: StaffAbsenceReason.illness,
        ),
        local(status: PresenceStatus.absent, arrival: '', lateMinutes: 0),
      ),
      HrPresenceDayAgreement.divergent,
    );
  });

  test('une ligne pas encore envoyée est la plus récente : corrigeable', () {
    final agreement = check(
      server(),
      local(status: PresenceStatus.present, sync: RecordSyncState.pending),
    );
    expect(agreement, HrPresenceDayAgreement.localAhead);
    expect(agreement.editable, isTrue);
  });
}
