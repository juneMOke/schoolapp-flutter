import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_card_dialog.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_day_leave_guard.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_register_day_actions.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_report_dialog.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_schedule_dialog.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_day_register.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/helpers/class_day_access.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/helpers/class_presence_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes de la journée entière : horaire, restants présents, valider,
/// rouvrir, relancer l'envoi. Chacun ouvre sa modale s'il en a une, puis
/// confie le geste au cubit.
///
/// Les gestes de jour ([days]), le changement de classe et les sorties
/// d'écran passent par la garde commune ([leaveGuard]) : quitter un appel
/// pointé mais pas validé demande.
class ClassRegisterActions {
  final BuildContext context;

  const ClassRegisterActions(this.context);

  ClassPresenceCubit get _cubit => context.read<ClassPresenceCubit>();

  /// L'appel affiché s'écrit (cf. `classDayLock`) : le bandeau en tire ses
  /// actions, la garde son attente.
  bool get canEditDay {
    final state = _cubit.state;
    final day = state.presenceDay;
    return day != null &&
        classDayLockIn(context, day, today: state.today) == null;
  }

  PresenceDayLeaveGuard get leaveGuard => PresenceDayLeaveGuard(
    context,
    isPending: () =>
        _cubit.shownDayEdited &&
        (_cubit.state.register?.marked ?? 0) > 0 &&
        canEditDay,
    title: () => AppLocalizations.of(context)!.classPresenceLeaveTitle(
      PresenceLabels.longDay(
        MaterialLocalizations.of(context),
        _cubit.state.day,
      ),
      _cubit.state.classroom?.name ?? '',
    ),
    message: () => AppLocalizations.of(
      context,
    )!.classPresenceLeaveMessage(_cubit.state.register?.unmarked.length ?? 0),
  );

  /// Flèches, Aujourd'hui, calendrier.
  PresenceRegisterDayActions get days =>
      PresenceRegisterDayActions(context, days: _cubit, guard: leaveGuard);

  /// L'horaire se lit ici ; il se règle au Pointage du personnel, sous le
  /// droit des RH (décision 5).
  Future<void> openSchedule() async {
    final day = _cubit.state.presenceDay;
    if (day == null) return;
    await EteeloFormDialog.show<void>(
      context,
      PresenceScheduleDialog(schedule: day.schedule, editable: false),
    );
  }

  void markRemaining() =>
      unawaited(_cubit.perform((c, day) => c.markRemainingPresent(day)));

  Future<void> validate(ClassDayRegister register, String classroomName) async {
    final l10n = AppLocalizations.of(context)!;
    final unmarked = register.unmarked;
    final choice = await EteeloCardDialog.show<PresenceReportChoice>(
      context,
      PresenceReportDialog(
        dayLabel: PresenceLabels.longDay(
          MaterialLocalizations.of(context),
          register.day.day,
        ),
        title: l10n.classPresenceReportTitle(classroomName),
        present: register.count(PresenceStatus.present),
        late: register.count(PresenceStatus.late),
        absent: register.count(PresenceStatus.absent),
        unmarked: [
          for (final line in unmarked) line.presenceView(l10n, classroomName),
        ],
        unjustified: register.toJustify,
        // Décision 2 : l'appel envoyé ne connaît pas « à pointer ».
        unmarkedOptional: false,
        unmarkedLabel: l10n.classPresenceReportUnmarked(unmarked.length),
        lockMessage: l10n.classPresenceReportLock,
        confirmLabel: l10n.classPresenceValidate,
      ),
    );
    if (choice == null || !context.mounted) return;
    if (days.reviewIfAsked(choice)) return;
    await _cubit.perform(
      (c, day) => c.validate(day, classroomName: classroomName),
    );
  }

  void reopen() => unawaited(_cubit.perform((c, day) => c.reopen(day)));

  void retry() => unawaited(_cubit.perform((c, day) => c.retry(day)));
}
