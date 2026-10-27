import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_day_leave_guard.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_day_navigation.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_day_picker.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_report_dialog.dart';

/// Les gestes de jour d'un registre — flèches, Aujourd'hui, calendrier —
/// toujours derrière la garde du jour ([guard]), et le retour aux non
/// pointés demandé par la modale de validation. Écrits une fois pour le
/// Pointage et pour l'appel.
class PresenceRegisterDayActions {
  final BuildContext context;
  final PresenceDayNavigation days;
  final PresenceDayLeaveGuard guard;

  const PresenceRegisterDayActions(
    this.context, {
    required this.days,
    required this.guard,
  });

  void stepDay(int direction) =>
      unawaited(guard.leaveThen(() => days.stepDay(direction)));

  void goToday() => unawaited(guard.leaveThen(days.goToday));

  /// Le calendrier du registre ; le jour choisi passe par la garde.
  Future<void> pickDay() async {
    final day = await pickPresenceDay(
      context,
      day: days.shownDay,
      firstDay: days.firstShownDay,
      lastDay: days.lastShownDay,
    );
    if (day == null || day == days.shownDay || !context.mounted) return;
    await guard.leaveThen(() => days.showDay(day));
  }

  /// La modale de validation a demandé à revoir les non pointés : le
  /// registre se filtre sur eux, rien n'est validé. Rend `true` quand c'est
  /// le cas.
  bool reviewIfAsked(PresenceReportChoice choice) {
    if (!choice.reviewUnmarked) return false;
    days.showOnlyUnmarked();
    return true;
  }
}
