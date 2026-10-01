import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_schedule_dialog.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_report_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';

/// Les gestes du jour entier : réglages, restants présents, valider, rouvrir.
/// Chacun ouvre sa modale s'il en a une, puis confie le geste au cubit.
class StaffRegisterActions {
  final BuildContext context;

  const StaffRegisterActions(this.context);

  StaffAttendanceCubit get _cubit => context.read<StaffAttendanceCubit>();

  Future<void> openSettings() async {
    final editable = PermissionGate.allows(
      context,
      kStaffAttendanceManageAccess.requires,
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
    );
  }

  void markRemaining() => unawaited(
    _cubit.perform(
      (c) =>
          c.markRemainingPresent(_cubit.state.snapshot, _cubit.state.register),
    ),
  );

  Future<void> validate(StaffDayRegister register) async {
    final l10n = AppLocalizations.of(context)!;
    final unmarked = register.unmarked.length;
    final choice = await EteeloFormDialog.show<PresenceReportChoice>(
      context,
      PresenceReportDialog(
        eyebrow: PresenceLabels.longDay(
          MaterialLocalizations.of(context),
          register.day,
        ),
        title: l10n.staffAttendanceReportTitle,
        present: register.count(PresenceStatus.present),
        late: register.count(PresenceStatus.late),
        absent: register.count(PresenceStatus.absent),
        // Seuls ceux qu'un contrat couvre ce jour-là sont marqués d'office.
        unmarked: unmarked,
        unjustified: register.toJustify,
        unmarkedLabel: l10n.staffAttendanceReportMarkRemaining(unmarked),
        lockMessage: l10n.staffAttendanceReportLock,
        confirmLabel: l10n.staffAttendanceReportConfirm,
      ),
    );
    if (choice == null || !context.mounted) return;
    await _cubit.perform(
      (c) => c.validateDay(
        _cubit.state.snapshot,
        _cubit.state.register,
        markRemaining: choice.markRemaining,
      ),
    );
  }

  void reopen() => unawaited(
    _cubit.perform((c) => c.reopenDay(_cubit.state.snapshot, _cubit.state.day)),
  );
}
