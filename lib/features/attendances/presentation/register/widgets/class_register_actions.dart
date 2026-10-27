import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_day_leave_guard.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_day_picker.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_report_dialog.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_schedule_dialog.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_day_register.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/helpers/class_day_access.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes de la journée entière : horaire, restants présents, valider,
/// rouvrir, relancer l'envoi. Chacun ouvre sa modale s'il en a une, puis
/// confie le geste au cubit.
///
/// Quitter un appel pointé mais pas validé — changer de jour ou de classe,
/// quitter l'écran — passe par la garde commune ([PresenceDayLeaveGuard]).
class ClassRegisterActions with PresenceDayLeaveGuard {
  @override
  final BuildContext context;

  ClassRegisterActions(this.context);

  ClassPresenceCubit get _cubit => context.read<ClassPresenceCubit>();

  @override
  bool get hasPendingDay {
    final state = _cubit.state;
    final register = state.register;
    return register != null &&
        register.marked > 0 &&
        !register.frozen &&
        classDayLockIn(context, register.day, today: state.today) == null;
  }

  @override
  String get leaveTitle =>
      AppLocalizations.of(context)!.classPresenceLeaveTitle(
        PresenceLabels.longDay(
          MaterialLocalizations.of(context),
          _cubit.state.day,
        ),
        _cubit.state.classroom?.name ?? '',
      );

  @override
  String get leaveMessage =>
      AppLocalizations.of(context)!.classPresenceLeaveMessage(
        _cubit.state.register?.count(PresenceStatus.none) ?? 0,
      );

  /// Le jour de classe précédent ou suivant, après la garde.
  void stepDay(int direction) =>
      unawaited(leaveDayThen(() => _cubit.stepDay(direction)));

  /// Le dernier jour de classe, après la garde.
  void goToday() => unawaited(leaveDayThen(_cubit.goToday));

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

  /// Le calendrier du registre.
  Future<void> pickDay() async {
    final state = _cubit.state;
    final day = await pickPresenceDay(
      context,
      day: state.day,
      firstDay: state.firstDay,
      lastDay: state.lastSchoolDay,
    );
    if (day == null || day == state.day || !context.mounted) return;
    await leaveDayThen(() => _cubit.showDay(day));
  }

  void markRemaining() =>
      unawaited(_cubit.perform((c, day) => c.markRemainingPresent(day)));

  Future<void> validate(ClassDayRegister register, String classroomName) async {
    final l10n = AppLocalizations.of(context)!;
    final unmarked = register.unmarked;
    final choice = await EteeloFormDialog.show<PresenceReportChoice>(
      context,
      PresenceReportDialog(
        eyebrow: PresenceLabels.longDay(
          MaterialLocalizations.of(context),
          register.day.day,
        ),
        title: l10n.classPresenceReportTitle(classroomName),
        present: register.count(PresenceStatus.present),
        late: register.count(PresenceStatus.late),
        absent: register.count(PresenceStatus.absent),
        unmarked: unmarked.length,
        unmarkedNames: [for (final line in unmarked) line.student.fullName],
        unjustified: register.toJustify,
        // Décision 2 : l'appel envoyé ne connaît pas « à pointer ».
        unmarkedOptional: false,
        unmarkedLabel: l10n.classPresenceReportUnmarked(unmarked.length),
        lockMessage: l10n.classPresenceReportLock,
        confirmLabel: l10n.classPresenceValidate,
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice.reviewUnmarked) {
      _cubit.setDayStatus(PresenceStatus.none);
      return;
    }
    await _cubit.perform(
      (c, day) => c.validate(day, classroomName: classroomName),
    );
  }

  void reopen() => unawaited(_cubit.perform((c, day) => c.reopen(day)));

  void retry() => unawaited(_cubit.perform((c, day) => c.retry(day)));
}
