import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_day_banner.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_validated_banner.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_lock.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_state.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_register_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau commun du registre, branché sur le Pointage : navigation de
/// jour, réglages, restants présents, valider le rapport.
class StaffDayBanner extends StatelessWidget {
  final StaffAttendanceState state;

  const StaffDayBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) => PermissionAware(builder: _build);

  Widget _build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<StaffAttendanceCubit>();
    final actions = StaffRegisterActions(context);
    final register = state.register;
    return PresenceDayBanner(
      eyebrow: state.isToday
          ? l10n.staffAttendanceEyebrowToday
          : l10n.staffAttendanceEyebrowPast,
      day: register.day,
      isToday: state.isToday,
      schedule: state.snapshot.settings,
      marked: register.marked,
      total: register.all.length,
      detail: [
        l10n.presenceMarkBadgeToMark(register.count(PresenceStatus.none)),
        if (register.pending > 0) l10n.presenceMarkOnTablet(register.pending),
      ].join(' · '),
      showActions:
          !register.frozen &&
          PermissionGate.allowsAccess(context, kStaffAttendanceWriteAccess),
      validateLabel: l10n.staffAttendanceValidateReport,
      onPrevious: state.canStepBack ? () => unawaited(cubit.stepDay(-1)) : null,
      onNext: state.isToday ? null : () => unawaited(cubit.stepDay(1)),
      onToday: () => unawaited(cubit.goToday()),
      onSettings: () => unawaited(actions.openSettings()),
      onMarkRemaining: register.unmarked.isEmpty ? null : actions.markRemaining,
      onValidate: register.isEmpty
          ? null
          : () => unawaited(actions.validate(register)),
    );
  }
}

/// Le rapport du jour validé. Une réouverture refusée laisse le jour validé,
/// pastille en échec : Rouvrir la repose.
class StaffValidatedBanner extends StatelessWidget {
  final StaffAttendanceState state;
  final StaffAttendanceLock lock;

  /// Un jour d'un mois clos ne se rouvre pas.
  final bool canReopen;

  const StaffValidatedBanner({
    super.key,
    required this.state,
    required this.lock,
    required this.canReopen,
  });

  @override
  Widget build(BuildContext context) => PermissionAware(builder: _build);

  Widget _build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final register = state.register;
    final when = PresenceLabels.moment(
      MaterialLocalizations.of(context),
      lock.lockedAt,
    );
    final by = lock.lockedByName;
    final mayReopen =
        canReopen &&
        PermissionGate.allowsAccess(context, kStaffAttendanceWriteAccess);
    return PresenceValidatedBanner(
      title: l10n.staffAttendanceValidatedTitle,
      byLine: by != null && when != null
          ? l10n.presenceMarkValidatedBy(by, when)
          : when,
      present:
          register.count(PresenceStatus.present) +
          register.count(PresenceStatus.none),
      late: register.count(PresenceStatus.late),
      absent: register.count(PresenceStatus.absent),
      sync: lock.syncState,
      onReopen: mayReopen ? StaffRegisterActions(context).reopen : null,
    );
  }
}
