import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_close_dialog.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_warning.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_closure.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_month_recap.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_state.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le mois peut-il être clos ? Un mois **terminé** (le serveur refuse le mois
/// en cours, lu sur son horloge), une année scolaire connue, pas encore clos.
bool canCloseClassMonth(ClassPresenceState state) {
  final data = state.monthData;
  if (data == null || data.closed || state.schoolYear == null) return false;
  return SchoolDayCalendar.daysOf(state.month).last.compareTo(state.today) < 0;
}

/// « Clôturer le mois » — sous `attendance.amend` (préfet, directeur de
/// discipline), une confirmation qui dit ce que la clôture fige.
class ClassMonthCloseButton extends StatelessWidget {
  final ClassPresenceState state;
  final ClassMonthRecap recap;

  const ClassMonthCloseButton({
    super.key,
    required this.state,
    required this.recap,
  });

  @override
  Widget build(BuildContext context) {
    if (!canCloseClassMonth(state) ||
        recap.isHoliday ||
        !PermissionGate.allowsAccess(context, kAttendanceAmendAccess)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    return EteeloButton.primary(
      label: l10n.classPresenceClose,
      icon: Icons.lock,
      onPressed: () => unawaited(_confirm(context)),
      fullWidth: false,
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final classroom = state.classroom!.name;
    var justified = 0;
    for (final row in recap.all) {
      justified += row.stats.absentJustified;
    }
    final confirmed = await EteeloFormDialog.show<bool>(
      context,
      PresenceMonthCloseDialog(
        title: l10n.classPresenceCloseTitle(
          PresenceLabels.month(MaterialLocalizations.of(context), state.month),
        ),
        confirmLabel: l10n.classPresenceCloseConfirm,
        consequences: [
          (
            text: l10n.classPresenceCloseFreeze(classroom),
            icon: Icons.lock_clock,
          ),
          (
            text: l10n.classPresenceCloseAbsences(
              recap.absentUnjustified,
              justified,
            ),
            icon: Icons.folder_shared_outlined,
          ),
          (
            text: l10n.classPresenceCloseToWatch(
              recap.count(ClassRecapFilter.toWatch),
            ),
            icon: Icons.flag_outlined,
          ),
        ],
        notMarkedWarning: recap.notMarked > 0
            ? l10n.classPresenceCloseNotMarked(recap.notMarked)
            : null,
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<ClassPresenceCubit>().closeMonth();
  }
}

/// Où en est la clôture du mois : close (et son envoi), refusée (avec la
/// raison), ou à venir quand le mois n'est pas fini.
class ClassMonthCloseState extends StatelessWidget {
  final ClassPresenceState state;
  final ClassPresenceClosure? closure;

  const ClassMonthCloseState({
    super.key,
    required this.state,
    required this.closure,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final closure = this.closure;
    if (closure == null || !closure.closes) {
      final refusal = closure?.refusal;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (refusal != null)
            PresenceWarning(
              icon: Icons.sync_problem,
              tone: PresenceStatus.absent,
              message: l10n.classPresenceCloseRefused(refusal),
            ),
          if (state.isCurrentMonth)
            PresenceWarning(
              icon: Icons.event_available_outlined,
              tone: PresenceStatus.none,
              message: l10n.classPresenceCloseNotEnded,
            ),
        ],
      );
    }
    final when =
        PresenceLabels.moment(
          MaterialLocalizations.of(context),
          closure.closedAt,
        ) ??
        '';
    return Row(
      children: [
        Expanded(
          child: PresenceWarning(
            icon: Icons.lock_outline,
            tone: PresenceStatus.present,
            message: l10n.classPresenceClosedOn(when),
          ),
        ),
        if (closure.recordSync != RecordSyncState.synced) ...[
          const SizedBox(width: AppSpacing.sm),
          RecordSyncPill(state: closure.recordSync),
        ],
      ],
    );
  }
}
