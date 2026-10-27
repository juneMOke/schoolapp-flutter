import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_card_dialog.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_leave_dialog.dart';

/// La garde d'un jour pointé mais pas validé, partagée par les registres (le
/// Pointage du personnel, l'appel d'une classe) : chaque module la construit
/// en disant quand son jour est en attente et ce que la popin en dit.
///
/// Rien n'est perdu en partant : les pointages sont sur la tablette. Ce qui
/// manque, c'est la validation — la question est un rappel, en modale carte
/// ([PresenceLeaveDialog]), qui offre aussi de valider avant de partir ;
/// jamais un blocage.
class PresenceDayLeaveGuard {
  final BuildContext context;

  /// Le jour affiché a des pointages, n'est pas validé, et le compte peut le
  /// valider. Relu à chaque question : l'état a pu changer depuis.
  final bool Function() isPending;

  /// « Le rapport du mardi 27 octobre n'est pas validé ».
  final String Function() title;

  /// Ce qui est gardé, et combien restent à pointer.
  final String Function() message;

  /// « Valider et quitter » : la validation du module (sa modale comprise),
  /// qui rend `true` quand le jour est validé. `null` : pas d'action.
  final Future<bool> Function()? validate;

  const PresenceDayLeaveGuard(
    this.context, {
    required this.isPending,
    required this.title,
    required this.message,
    this.validate,
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

  /// La popin de sortie. « Valider et quitter » enchaîne la validation :
  /// on ne part que si le jour est validé, sinon on reste dessus.
  Future<bool> _ask() async {
    final validate = this.validate;
    final choice = await EteeloCardDialog.show<PresenceLeaveChoice>(
      context,
      PresenceLeaveDialog(
        title: title(),
        message: message(),
        canValidate: validate != null,
      ),
    );
    return switch (choice) {
      PresenceLeaveChoice.leave => true,
      PresenceLeaveChoice.validate =>
        validate != null && context.mounted && await validate(),
      PresenceLeaveChoice.stay || null => false,
    };
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
