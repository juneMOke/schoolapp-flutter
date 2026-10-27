import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_presence_view.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_day_leave_guard.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_register_day_actions.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_card_dialog.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_schedule_dialog.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_report_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';

/// Les gestes du jour entier : réglages, restants présents, valider, rouvrir.
/// Chacun ouvre sa modale s'il en a une, puis confie le geste au cubit.
///
/// Les gestes de jour ([days]) et les sorties d'écran passent par la garde
/// commune ([leaveGuard]) : quitter un jour pointé mais pas validé demande.
class StaffRegisterActions {
  final BuildContext context;

  const StaffRegisterActions(this.context);

  StaffAttendanceCubit get _cubit => context.read<StaffAttendanceCubit>();

  /// Le jour affiché s'écrit : ni validé ni d'un mois clos, et le compte a
  /// le droit d'écrire. Le bandeau en tire ses actions, la garde son attente.
  bool get canEditDay =>
      !_cubit.state.register.frozen &&
      PermissionGate.allowsAccess(context, kStaffAttendanceWriteAccess);

  PresenceDayLeaveGuard get leaveGuard => PresenceDayLeaveGuard(
    context,
    isPending: () =>
        _cubit.shownDayEdited && _cubit.state.register.marked > 0 && canEditDay,
    title: () => AppLocalizations.of(context)!.staffAttendanceLeaveTitle(
      PresenceLabels.longDay(
        MaterialLocalizations.of(context),
        _cubit.state.day,
      ),
    ),
    message: () => AppLocalizations.of(
      context,
    )!.staffAttendanceLeaveMessage(_cubit.state.register.unmarked.length),
    validate: () => validate(_cubit.state.register),
  );

  /// Flèches, Aujourd'hui, calendrier : le jour choisi passe par le cubit,
  /// donc par l'adresse (`?jour=`).
  PresenceRegisterDayActions get days =>
      PresenceRegisterDayActions(context, days: _cubit, guard: leaveGuard);

  Future<void> openSettings() async {
    final editable = PermissionGate.allowsAccess(
      context,
      kStaffAttendanceManageAccess,
    );
    final schedule = await EteeloFormDialog.show<PresenceSchedule>(
      context,
      PresenceScheduleDialog(
        schedule: _cubit.state.snapshot.settings,
        editable: editable,
      ),
    );
    if (schedule == null || !context.mounted) return;
    await _cubit.perform(
      (c) => c.saveSettings(
        StaffAttendanceSettings(
          start: schedule.start,
          toleranceMinutes: schedule.toleranceMinutes,
        ),
      ),
      touchesDay: false,
    );
  }

  void markRemaining() => unawaited(
    _cubit.perform(
      (c) =>
          c.markRemainingPresent(_cubit.state.snapshot, _cubit.state.register),
    ),
  );

  /// Valide la journée après sa modale ; rend `true` quand le jour est
  /// validé (« Valider et quitter » ne part qu'à cette condition).
  Future<bool> validate(StaffDayRegister register) async {
    final l10n = AppLocalizations.of(context)!;
    final unmarked = register.unmarked;
    final choice = await EteeloCardDialog.show<PresenceReportChoice>(
      context,
      PresenceReportDialog(
        dayLabel: PresenceLabels.longDay(
          MaterialLocalizations.of(context),
          register.day,
        ),
        title: l10n.staffAttendanceReportTitle,
        present: register.count(PresenceStatus.present),
        late: register.count(PresenceStatus.late),
        absent: register.count(PresenceStatus.absent),
        // Seuls ceux qu'un contrat couvre ce jour-là sont marqués d'office.
        unmarked: [for (final row in unmarked) row.presenceView(l10n)],
        unjustified: register.toJustify,
        lockMessage: l10n.staffAttendanceReportLock,
        confirmLabel: l10n.staffAttendanceReportConfirm,
      ),
    );
    if (choice == null || !context.mounted) return false;
    if (days.reviewIfAsked(choice)) return false;
    await _cubit.perform(
      (c) => c.validateDay(
        _cubit.state.snapshot,
        _cubit.state.register,
        markRemaining: choice.markRemaining,
      ),
    );
    return _cubit.state.register.frozen;
  }

  void reopen() => unawaited(
    _cubit.perform((c) => c.reopenDay(_cubit.state.snapshot, _cubit.state.day)),
  );
}
