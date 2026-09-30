import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_dialog.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/dialogs/staff_attendance_settings_dialog.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/dialogs/staff_day_report_dialog.dart';

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
    final settings = await StaffDialog.show<StaffAttendanceSettings>(
      context,
      StaffAttendanceSettingsDialog(
        settings: _cubit.state.snapshot.settings,
        editable: editable,
      ),
    );
    if (settings == null || !context.mounted) return;
    await _cubit.perform((c) => c.saveSettings(settings));
  }

  void markRemaining() => unawaited(
    _cubit.perform(
      (c) =>
          c.markRemainingPresent(_cubit.state.snapshot, _cubit.state.register),
    ),
  );

  Future<void> validate(StaffDayRegister register) async {
    final choice = await StaffDialog.show<StaffReportChoice>(
      context,
      StaffDayReportDialog(
        register: register,
        dayLabel: StaffAttendanceLabels.longDay(
          MaterialLocalizations.of(context),
          register.day,
        ),
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
