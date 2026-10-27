import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La garde d'un jour pointé mais pas validé, partagée par les registres (le
/// Pointage du personnel, l'appel d'une classe).
///
/// Rien n'est perdu en partant : les pointages sont sur la tablette. Ce qui
/// manque, c'est la validation — la question est un rappel, posée avec la
/// popin de la charte (celle de l'inscription), jamais un blocage.
///
/// Les gestes du jour entier d'un registre la mêlent ; chacun dit quand le
/// jour est en attente et ce que la popin en dit.
mixin PresenceDayLeaveGuard {
  BuildContext get context;

  /// Le jour affiché a des pointages, n'est pas validé, et le compte peut le
  /// valider.
  bool get hasPendingDay;

  /// « Le rapport du mardi 27 octobre n'est pas validé ».
  String get leaveTitle;

  /// Ce qui est gardé, et combien restent à pointer.
  String get leaveMessage;

  /// Peut-on quitter le jour affiché ? Sans attente, sans question.
  Future<bool> mayLeaveDay() async {
    if (!hasPendingDay) return true;
    final l10n = AppLocalizations.of(context)!;
    return showAppConfirmationDialog(
      context: context,
      title: leaveTitle,
      message: leaveMessage,
      confirmLabel: l10n.presenceMarkLeaveConfirm,
      cancelLabel: l10n.presenceMarkLeaveStay,
      headerIcon: Icons.pending_actions_outlined,
      headerIconColor: AppColors.presenceMarkLateInk,
      confirmIcon: Icons.logout_rounded,
    );
  }

  /// Change de jour ([move]) après la question, s'il y a lieu.
  Future<void> leaveDayThen(Future<void> Function() move) async {
    if (!await mayLeaveDay() || !context.mounted) return;
    await move();
  }
}

/// Pose la garde d'un registre sur les sorties de l'écran (menu, Précédent
/// du navigateur, lien, fermeture de l'onglet) : [RouteExitGuard], avec la
/// question de [guard].
class PresenceDayExitGuard extends StatelessWidget {
  final PresenceDayLeaveGuard guard;
  final Widget child;

  const PresenceDayExitGuard({
    super.key,
    required this.guard,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => RouteExitGuard(
    hasUnsavedWork: () => guard.hasPendingDay,
    confirmExit: guard.mayLeaveDay,
    child: child,
  );
}
