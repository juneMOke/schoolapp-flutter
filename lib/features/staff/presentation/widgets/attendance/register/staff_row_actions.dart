import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_notice.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_row_view.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_justification_dialog.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_time_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

/// Les gestes sur l'agent d'une ligne du registre, **partagés** par la carte
/// de la grille et la ligne de la liste : ouvrir une modale, puis confier le
/// geste au cubit.
///
/// Un compte sans `hr.attendance.write`, ou un jour figé, intercepte tout,
/// avant même d'ouvrir une modale : l'écran dit pourquoi au lieu d'offrir une
/// saisie vouée au refus (un 403 en file d'envoi est terminal).
///
/// Chaque geste relit la ligne **au moment où il part** ([_row]) : la ligne
/// affichée a pu changer entre-temps (double toucher, pull pendant une
/// modale), et partir de l'ancienne écraserait la plus récente.
class StaffRowActions implements PresenceRowActions {
  final BuildContext context;
  final StaffDayRow row;

  /// Le jour est-il figé (rapport validé, mois clos) ?
  final bool frozen;

  const StaffRowActions(this.context, this.row, {required this.frozen});

  /// Le compte détient-il `hr.attendance.write` ?
  bool get canWrite =>
      PermissionGate.allowsAccess(context, kStaffAttendanceWriteAccess);

  StaffAttendanceCubit get _cubit => context.read<StaffAttendanceCubit>();

  /// La ligne de cet agent dans l'état courant du cubit.
  StaffDayRow get _row {
    for (final current in _cubit.state.register.all) {
      if (current.member.id == row.member.id && current.day == row.day) {
        return current;
      }
    }
    return row;
  }

  /// Heures de départ proposées d'office.
  static final List<ClockTime> departureShortcuts = [
    ClockTime.fromMinutes(12 * 60 + 30),
    ClockTime.fromMinutes(14 * 60),
    ClockTime.fromMinutes(15 * 60 + 30),
  ];

  bool _intercept() {
    final kind = !canWrite
        ? StaffAttendanceNoticeKind.forbidden
        : frozen
        ? StaffAttendanceNoticeKind.dayFrozen
        : null;
    if (kind == null) return false;
    _cubit.announce(StaffAttendanceNotice(kind));
    return true;
  }

  @override
  void cycle() {
    if (_intercept()) return;
    unawaited(_cubit.perform((c) => c.cycle(_cubit.state.snapshot, _row)));
  }

  @override
  void choose(PresenceStatus status) {
    if (_intercept()) return;
    unawaited(
      _cubit.perform((c) => c.choose(_cubit.state.snapshot, _row, status)),
    );
  }

  @override
  void clear() {
    if (_intercept()) return;
    unawaited(_cubit.perform((c) => c.clear(_cubit.state.snapshot, _row)));
  }

  @override
  void retry() {
    if (_intercept()) return;
    unawaited(_cubit.perform((c) => c.retry(_cubit.state.snapshot, _row)));
  }

  /// Une heure de plus ou de moins pour un vacataire à l'heure.
  void adjustHours(int deltaHours) {
    if (_intercept()) return;
    unawaited(
      _cubit.perform((c) {
        final fresh = _row;
        final current = fresh.record?.workedMinutes ?? 0;
        return c.setWorked(
          _cubit.state.snapshot,
          fresh,
          current + deltaHours * 60,
        );
      }),
    );
  }

  @override
  Future<void> editArrival() async {
    if (_intercept()) return;
    final l10n = AppLocalizations.of(context)!;
    final settings = _cubit.state.snapshot.settings;
    final now = ClockTime.of(DateTime.now());
    final choice = await EteeloFormDialog.show<PresenceTimeChoice>(
      context,
      PresenceTimeDialog(
        title: l10n.presenceMarkTimeArrivalTitle(_name),
        initial: row.record?.arrival,
        schedule: settings,
        shortcuts: [
          PresenceTimeShortcut(l10n.presenceMarkTimeNow, now),
          PresenceTimeShortcut(l10n.presenceMarkTimeStart, settings.start),
          PresenceTimeShortcut(
            l10n.presenceMarkTimePlus(15),
            settings.start.plus(15),
          ),
          PresenceTimeShortcut(
            l10n.presenceMarkTimePlus(30),
            settings.start.plus(30),
          ),
        ],
      ),
    );
    final time = choice?.time;
    if (time == null || !context.mounted) return;
    await _cubit.perform(
      (c) => c.setArrival(_cubit.state.snapshot, _row, time),
    );
  }

  Future<void> editDeparture() async {
    if (_intercept()) return;
    final l10n = AppLocalizations.of(context)!;
    final current = row.record?.departure;
    final choice = await EteeloFormDialog.show<PresenceTimeChoice>(
      context,
      PresenceTimeDialog(
        title: l10n.presenceMarkTimeDepartureTitle(_name),
        initial: current,
        canClear: current != null,
        shortcuts: [
          PresenceTimeShortcut(
            l10n.presenceMarkTimeNow,
            ClockTime.of(DateTime.now()),
          ),
          for (final time in departureShortcuts)
            PresenceTimeShortcut(time.wire, time),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    await _cubit.perform(
      (c) => c.setDeparture(_cubit.state.snapshot, _row, choice.time),
    );
  }

  @override
  Future<void> justify() async {
    if (_intercept()) return;
    final StaffAttendanceRecord? record = _row.record;
    if (record == null || !record.status.isIncident) return;
    final l10n = AppLocalizations.of(context)!;
    final choice =
        await EteeloFormDialog.show<
          PresenceJustificationChoice<StaffAbsenceReason>
        >(
          context,
          PresenceJustificationDialog<StaffAbsenceReason>(
            name: _name,
            status: record.status,
            lateMinutes: record.lateMinutes,
            initial: record.justification,
            reasons: StaffAbsenceReason.values,
            reasonLabel: (reason) => StaffAttendanceLabels.reason(l10n, reason),
            dayLabel: PresenceLabels.longDay(
              MaterialLocalizations.of(context),
              row.day,
            ),
          ),
        );
    if (choice == null || !context.mounted) return;
    await _cubit.perform(
      (c) => c.justify(_cubit.state.snapshot, _row, choice.justification),
    );
  }

  String get _name => row.member.fullName;
}
