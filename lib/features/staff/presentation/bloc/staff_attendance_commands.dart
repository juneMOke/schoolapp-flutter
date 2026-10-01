import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_attendance_editor.dart';
import 'package:school_app_flutter/core/presence/domain/presence_rules.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_notice.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_command_outcome.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

/// Les gestes du Pointage, sans état : chacun construit la ligne cohérente
/// (l'éditeur du domaine), l'enregistre, et rend ce que l'écran annonce —
/// `null` quand il n'y a rien à dire.
///
/// **Un jour figé** (rapport validé, mois clos) refuse tout geste avant
/// d'écrire : l'écran l'annonce au lieu de laisser partir une écriture vouée
/// au refus.
class StaffAttendanceCommands {
  final SaveStaffAttendanceUseCase _save;
  final RecordStaffAttendanceGestureUseCase _gesture;
  final SaveStaffAttendanceSettingsUseCase _settings;
  final DateTime Function() _now;

  const StaffAttendanceCommands({
    required SaveStaffAttendanceUseCase save,
    required RecordStaffAttendanceGestureUseCase gesture,
    required SaveStaffAttendanceSettingsUseCase settings,
    DateTime Function() now = DateTime.now,
  }) : _save = save,
       _gesture = gesture,
       _settings = settings,
       _now = now;

  /// Un toucher sur une carte : le statut suivant du cycle.
  Future<StaffAttendanceNotice?> cycle(
    StaffAttendanceSnapshot snapshot,
    StaffDayRow row,
  ) => choose(snapshot, row, PresenceRules.nextInCycle(row.status));

  /// Un choix direct (vue liste). Retoucher le statut actif l'efface.
  Future<StaffAttendanceNotice?> choose(
    StaffAttendanceSnapshot snapshot,
    StaffDayRow row,
    PresenceStatus status,
  ) {
    if (status == row.status) return clear(snapshot, row);
    return _edit(
      snapshot,
      row,
      (editor, record) => editor.mark(record, status, ClockTime.of(_now())),
    );
  }

  /// Renvoie tel quel un pointage refusé (après correction de la cause).
  Future<StaffAttendanceNotice?> retry(
    StaffAttendanceSnapshot snapshot,
    StaffDayRow row,
  ) async {
    final record = row.record;
    if (record == null) return null;
    final frozen = StaffCommandOutcome.frozen(snapshot, row.day);
    if (frozen != null) return frozen;
    return StaffCommandOutcome.of(await _save([record]), null);
  }

  /// Remet « à pointer ».
  Future<StaffAttendanceNotice?> clear(
    StaffAttendanceSnapshot snapshot,
    StaffDayRow row,
  ) => _edit(
    snapshot,
    row,
    (editor, record) => editor.clear(record),
    done: StaffAttendanceNotice(
      StaffAttendanceNoticeKind.cleared,
      name: row.member.fullName,
    ),
  );

  Future<StaffAttendanceNotice?> setArrival(
    StaffAttendanceSnapshot snapshot,
    StaffDayRow row,
    ClockTime arrival,
  ) => _edit(
    snapshot,
    row,
    (editor, record) => editor.setArrival(record, arrival),
  );

  Future<StaffAttendanceNotice?> setDeparture(
    StaffAttendanceSnapshot snapshot,
    StaffDayRow row,
    ClockTime? departure,
  ) => _edit(
    snapshot,
    row,
    (editor, record) => editor.setDeparture(record, departure),
  );

  Future<StaffAttendanceNotice?> setWorked(
    StaffAttendanceSnapshot snapshot,
    StaffDayRow row,
    int minutes,
  ) => _edit(
    snapshot,
    row,
    (editor, record) => editor.setWorked(record, minutes),
  );

  /// Pose (ou retire, [justification] `null`) une justification.
  Future<StaffAttendanceNotice?> justify(
    StaffAttendanceSnapshot snapshot,
    StaffDayRow row,
    StaffAttendanceJustification? justification,
  ) => _edit(
    snapshot,
    row,
    (editor, record) => editor.justify(record, justification),
    done: StaffAttendanceNotice(
      justification == null
          ? StaffAttendanceNoticeKind.justificationRemoved
          : StaffAttendanceNoticeKind.justified,
      name: row.member.fullName,
    ),
  );

  /// Marque tous les « à pointer » du jour présents à l'heure de début.
  Future<StaffAttendanceNotice?> markRemainingPresent(
    StaffAttendanceSnapshot snapshot,
    StaffDayRegister register,
  ) async {
    final frozen = StaffCommandOutcome.frozen(snapshot, register.day);
    if (frozen != null) return frozen;
    final records = _remaining(snapshot, register);
    if (records.isEmpty) return null;
    return StaffCommandOutcome.of(
      await _save(records),
      StaffAttendanceNotice(
        StaffAttendanceNoticeKind.remainingMarked,
        count: records.length,
      ),
    );
  }

  /// Valide le rapport du jour. Avec [markRemaining], les « à pointer » sont
  /// d'abord marqués présents : ils partent **avant** le geste, qui les attend.
  Future<StaffAttendanceNotice?> validateDay(
    StaffAttendanceSnapshot snapshot,
    StaffDayRegister register, {
    required bool markRemaining,
  }) async {
    final frozen = StaffCommandOutcome.frozen(snapshot, register.day);
    if (frozen != null) return frozen;
    if (markRemaining) {
      final records = _remaining(snapshot, register);
      if (records.isNotEmpty) {
        final saved = await _save(records);
        if (saved.isLeft()) return StaffCommandOutcome.of(saved, null);
      }
    }
    return StaffCommandOutcome.of(
      await _gesture(StaffAttendanceGesture.validateDay, register.day),
      const StaffAttendanceNotice(StaffAttendanceNoticeKind.reportValidated),
    );
  }

  /// Rouvre le rapport du jour ; impossible dans un mois clos.
  Future<StaffAttendanceNotice?> reopenDay(
    StaffAttendanceSnapshot snapshot,
    String day,
  ) async {
    if (snapshot.isMonthClosed(SchoolDayCalendar.monthOf(day))) {
      return const StaffAttendanceNotice(StaffAttendanceNoticeKind.monthFrozen);
    }
    return StaffCommandOutcome.of(
      await _gesture(StaffAttendanceGesture.reopenDay, day),
      const StaffAttendanceNotice(StaffAttendanceNoticeKind.reportReopened),
    );
  }

  /// Clôt le mois `YYYY-MM` — irréversible depuis la tablette.
  Future<StaffAttendanceNotice?> closeMonth(String month) async =>
      StaffCommandOutcome.of(
        await _gesture(
          StaffAttendanceGesture.closeMonth,
          SchoolDayCalendar.firstOf(month),
        ),
        StaffAttendanceNotice(
          StaffAttendanceNoticeKind.monthClosed,
          month: month,
        ),
      );

  Future<StaffAttendanceNotice?> saveSettings(
    StaffAttendanceSettings settings,
  ) async => StaffCommandOutcome.of(
    await _settings(settings),
    const StaffAttendanceNotice(StaffAttendanceNoticeKind.settingsSaved),
  );

  Future<StaffAttendanceNotice?> _edit(
    StaffAttendanceSnapshot snapshot,
    StaffDayRow row,
    StaffAttendanceRecord Function(
      StaffAttendanceEditor editor,
      StaffAttendanceRecord record,
    )
    change, {
    StaffAttendanceNotice? done,
  }) async {
    final frozen = StaffCommandOutcome.frozen(snapshot, row.day);
    if (frozen != null) return frozen;
    final record = _recordOf(row);
    final editor = StaffAttendanceEditor(PresenceRules(snapshot.settings));
    final changed = change(editor, record);
    if (changed == record) return null;
    return StaffCommandOutcome.of(await _save([changed]), done);
  }

  /// La ligne d'un agent pour le jour du registre, vierge s'il n'a pas de
  /// pointage.
  static StaffAttendanceRecord _recordOf(StaffDayRow row) =>
      row.record ??
      StaffAttendanceEditor.blank(
        staffMemberId: row.member.id,
        workDate: row.day,
      );

  List<StaffAttendanceRecord> _remaining(
    StaffAttendanceSnapshot snapshot,
    StaffDayRegister register,
  ) {
    final editor = StaffAttendanceEditor(PresenceRules(snapshot.settings));
    final start = snapshot.settings.start;
    return [
      for (final row in register.unmarked)
        editor.setArrival(_recordOf(row), start),
    ];
  }
}
