import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_report_dialog.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_schedule_dialog.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_day_register.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes de la journée entière : horaire, restants présents, valider,
/// rouvrir, relancer l'envoi. Chacun ouvre sa modale s'il en a une, puis
/// confie le geste au cubit.
class ClassRegisterActions {
  final BuildContext context;

  const ClassRegisterActions(this.context);

  ClassPresenceCubit get _cubit => context.read<ClassPresenceCubit>();

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
    final unmarked = register.unmarked.length;
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
        unmarked: unmarked,
        unjustified: register.toJustify,
        // Décision 2 : l'appel envoyé ne connaît pas « à pointer ».
        unmarkedOptional: false,
        unmarkedLabel: l10n.classPresenceReportUnmarked(unmarked),
        lockMessage: l10n.classPresenceReportLock,
        confirmLabel: l10n.classPresenceValidate,
      ),
    );
    if (choice == null || !context.mounted) return;
    await _cubit.perform(
      (c, day) => c.validate(day, classroomName: classroomName),
    );
  }

  void reopen() => unawaited(_cubit.perform((c, day) => c.reopen(day)));

  void retry() => unawaited(_cubit.perform((c, day) => c.retry(day)));
}
