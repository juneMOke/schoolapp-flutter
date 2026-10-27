import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La garde d'un jour pointé mais pas validé, partagée par les registres (le
/// Pointage du personnel, l'appel d'une classe) : chaque module la construit
/// en disant quand son jour est en attente et ce que la popin en dit.
///
/// Rien n'est perdu en partant : les pointages sont sur la tablette. Ce qui
/// manque, c'est la validation — la question est un rappel, posée avec la
/// popin de la charte (celle de l'inscription), jamais un blocage.
class PresenceDayLeaveGuard {
  final BuildContext context;

  /// Le jour affiché a des pointages, n'est pas validé, et le compte peut le
  /// valider. Relu à chaque question : l'état a pu changer depuis.
  final bool Function() isPending;

  /// « Le rapport du mardi 27 octobre n'est pas validé ».
  final String Function() title;

  /// Ce qui est gardé, et combien restent à pointer.
  final String Function() message;

  const PresenceDayLeaveGuard(
    this.context, {
    required this.isPending,
    required this.title,
    required this.message,
  });

  /// Une question à la fois, toutes gardes confondues : un Précédent du
  /// navigateur pendant la popin d'un changement de jour n'en superpose pas
  /// une seconde.
  static bool _asking = false;

  /// Peut-on quitter le jour affiché ? Sans attente, sans question.
  Future<bool> mayLeave() async {
    if (!isPending()) return true;
    if (_asking) return false;
    _asking = true;
    try {
      return await _ask();
    } finally {
      _asking = false;
    }
  }

  Future<bool> _ask() {
    final l10n = AppLocalizations.of(context)!;
    return showAppConfirmationDialog(
      context: context,
      title: title(),
      message: message(),
      confirmLabel: l10n.presenceMarkLeaveConfirm,
      cancelLabel: l10n.presenceMarkLeaveStay,
      headerIcon: Icons.pending_actions_outlined,
      headerIconColor: AppColors.presenceMarkLateInk,
      confirmIcon: Icons.logout_rounded,
    );
  }

  /// Quitte le jour ([move]) après la question, s'il y a lieu ; rend `false`
  /// quand on reste.
  Future<bool> leaveThen(Future<void> Function() move) async {
    if (!await mayLeave() || !context.mounted) return false;
    await move();
    return true;
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
    hasUnsavedWork: guard.isPending,
    confirmExit: guard.mayLeave,
    child: child,
  );
}
