import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_day_banner.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_validated_banner.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_warning.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_day_register.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/helpers/class_day_access.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/class_register_actions.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau commun du registre, branché sur l'appel d'une classe.
class ClassDayBanner extends StatelessWidget {
  final ClassPresenceState state;
  final ClassDayRegister register;
  final String classroomName;

  const ClassDayBanner({
    super.key,
    required this.state,
    required this.register,
    required this.classroomName,
  });

  @override
  Widget build(BuildContext context) => PermissionAware(builder: _build);

  Widget _build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ClassPresenceCubit>();
    final actions = ClassRegisterActions(context);
    final unmarked = register.count(PresenceStatus.none);
    return PresenceDayBanner(
      eyebrow: state.isToday
          ? l10n.classPresenceEyebrowToday(classroomName)
          : l10n.classPresenceEyebrowPast(classroomName),
      day: state.day,
      isToday: state.isToday,
      schedule: register.day.schedule,
      marked: register.marked,
      total: register.all.length,
      detail: [
        if (unmarked > 0)
          l10n.presenceMarkBadgeToMark(unmarked)
        else
          l10n.classPresenceAllMarked,
        if (register.pending > 0) l10n.presenceMarkOnTablet(register.pending),
      ].join(' · '),
      showActions:
          classDayLockIn(context, register.day, today: state.today) == null,
      validateLabel: l10n.classPresenceValidate,
      onPrevious: state.canStepBack ? () => unawaited(cubit.stepDay(-1)) : null,
      onNext: state.isToday ? null : () => unawaited(cubit.stepDay(1)),
      onToday: () => unawaited(cubit.goToday()),
      onSettings: () => unawaited(actions.openSchedule()),
      onMarkRemaining: unmarked == 0 ? null : actions.markRemaining,
      onValidate: register.isEmpty
          ? null
          : () => unawaited(actions.validate(register, classroomName)),
    );
  }
}

/// L'appel validé : qui, quand (le dernier envoi), combien, où en est
/// l'envoi — Réessayer s'il a été refusé, Rouvrir si le compte le peut.
class ClassValidatedBanner extends StatelessWidget {
  final ClassPresenceState state;
  final ClassDayRegister register;

  const ClassValidatedBanner({
    super.key,
    required this.state,
    required this.register,
  });

  @override
  Widget build(BuildContext context) => PermissionAware(builder: _build);

  Widget _build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final day = register.day;
    final actions = ClassRegisterActions(context);
    final sentAt = day.lastSentAt;
    final when = sentAt == null
        ? null
        : PresenceLabels.moment(
            MaterialLocalizations.of(context),
            DateTime.fromMillisecondsSinceEpoch(sentAt).toIso8601String(),
          );
    final by = day.takenBy;
    final canWrite = PermissionGate.allowsAccess(
      context,
      kAttendanceRecordAccess,
    );
    final past = day.day.compareTo(state.today) < 0;
    final canAmend = PermissionGate.allowsAccess(
      context,
      kAttendanceAmendAccess,
    );
    final canReopen = canWrite && !day.monthClosed && (!past || canAmend);
    final refusal = day.refusal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PresenceValidatedBanner(
          title: l10n.classPresenceValidatedTitle,
          byLine: when == null
              ? null
              : by == null
              ? l10n.classPresenceUpdatedAt(when)
              : l10n.classPresenceUpdatedBy(by, when),
          present: register.count(PresenceStatus.present),
          late: register.count(PresenceStatus.late),
          absent: register.count(PresenceStatus.absent),
          sync: day.sync,
          onReopen: canReopen ? actions.reopen : null,
          onRetry: canWrite && !day.monthClosed ? actions.retry : null,
        ),
        if (day.sync == RecordSyncState.failed && refusal != null) ...[
          const SizedBox(height: AppSpacing.sm),
          PresenceWarning(
            icon: Icons.sync_problem,
            tone: PresenceStatus.absent,
            message: l10n.classPresenceRefused(refusal),
          ),
        ],
        if (canWrite && past && !canAmend && !day.monthClosed) ...[
          const SizedBox(height: AppSpacing.sm),
          PresenceWarning(
            icon: Icons.lock_outline,
            tone: PresenceStatus.none,
            message: l10n.classPresenceReopenPastHint,
          ),
        ],
      ],
    );
  }
}
