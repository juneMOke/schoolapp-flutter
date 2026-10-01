import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_row_view.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_justification_dialog.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_time_dialog.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_day.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_day_lock.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_notice.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes sur l'élève d'une ligne, **partagés** par la carte de la grille
/// et la ligne de la liste : ouvrir une modale, puis confier le geste au
/// cubit.
///
/// Un compte sans le droit de faire l'appel, un appel validé ou un mois clos
/// interceptent avant même d'ouvrir une modale — sauf « Justifier », qui
/// reste ouvert sur un appel validé (décision 9). Chaque geste relit la ligne
/// **au moment où il part** ([_line]) : partir de la ligne affichée
/// écraserait une marque plus récente.
class ClassRowActions implements PresenceRowActions {
  final BuildContext context;
  final ClassPresenceLine line;

  const ClassRowActions(this.context, this.line);

  ClassPresenceCubit get _cubit => context.read<ClassPresenceCubit>();

  ClassPresenceDay? get _day => _cubit.state.presenceDay;

  /// La ligne de cet élève dans l'état courant.
  ClassPresenceLine get _line {
    for (final current in _day?.lines ?? const <ClassPresenceLine>[]) {
      if (current.student.id == line.student.id) return current;
    }
    return line;
  }

  /// Un geste refusé s'annonce au lieu d'écrire. [justifying] laisse passer
  /// la justification d'un appel validé (décision 9).
  bool _intercept({bool justifying = false}) {
    final day = _day;
    if (day == null) return true;
    final lock = classDayLock(
      day,
      today: _cubit.state.today,
      canWrite: PermissionGate.allowsAccess(context, kAttendanceRecordAccess),
      canAmend: PermissionGate.allowsAccess(context, kAttendanceAmendAccess),
      justifying: justifying,
    );
    if (lock == null) return false;
    _cubit.announce(ClassPresenceNotice(ClassPresenceNoticeKind.ofLock(lock)));
    return true;
  }

  @override
  void cycle() {
    if (_intercept()) return;
    unawaited(_cubit.perform((c, day) => c.cycle(day, _line)));
  }

  @override
  void choose(PresenceStatus status) {
    if (_intercept()) return;
    unawaited(_cubit.perform((c, day) => c.choose(day, _line, status)));
  }

  @override
  void clear() {
    if (_intercept()) return;
    unawaited(_cubit.perform((c, day) => c.clear(day, _line)));
  }

  /// L'envoi se reprend dans le bandeau de l'appel, pas ligne par ligne.
  @override
  void retry() {}

  @override
  Future<void> editArrival() async {
    if (_intercept()) return;
    final l10n = AppLocalizations.of(context)!;
    final schedule = _day!.schedule;
    final now = ClockTime.of(DateTime.now());
    final choice = await EteeloFormDialog.show<PresenceTimeChoice>(
      context,
      PresenceTimeDialog(
        title: l10n.presenceMarkTimeArrivalTitle(line.student.fullName),
        initial: _line.mark.arrival,
        schedule: schedule,
        shortcuts: PresenceTimeShortcut.arrivals(l10n, schedule, now),
      ),
    );
    final time = choice?.time;
    if (time == null || !context.mounted) return;
    await _cubit.perform((c, day) => c.setArrival(day, _line, time));
  }

  @override
  Future<void> justify() async {
    if (_intercept(justifying: true)) return;
    final current = _line;
    if (!current.status.isIncident) return;
    final l10n = AppLocalizations.of(context)!;
    final choice = await PresenceJustificationDialog.show<AbsenceReason>(
      context,
      name: current.student.fullName,
      status: current.status,
      lateMinutes: current.mark.lateMinutes,
      day: _day!.day,
      initial: current.mark.justification,
      reasons: kSelectableAbsenceReasons,
      reasonLabel: (reason) => reason.getDisplayName(l10n),
    );
    if (choice == null || !context.mounted) return;
    await _cubit.perform(
      (c, day) => c.justify(day, _line, choice.justification),
    );
  }
}
