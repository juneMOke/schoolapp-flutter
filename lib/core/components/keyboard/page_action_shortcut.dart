import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/components/keyboard/route_key_shortcut.dart';

/// Les gestes d'écran d'un poste de bureau, aux touches de tout logiciel de
/// gestion.
enum PageAction {
  /// Ctrl+N : nouveau (dossier, dépense, communiqué…).
  create([
    SingleActivator(LogicalKeyboardKey.keyN, control: true),
    SingleActivator(LogicalKeyboardKey.keyN, meta: true),
  ]),

  /// F5, Ctrl+R : relire. Sur le web, la page n'est plus rechargée en
  /// entier — le travail en cours de l'onglet ne se perd pas.
  refresh([
    SingleActivator(LogicalKeyboardKey.f5),
    SingleActivator(LogicalKeyboardKey.keyR, control: true),
    SingleActivator(LogicalKeyboardKey.keyR, meta: true),
  ]),

  /// Ctrl+P : imprimer la pièce affichée. Sur le web, l'impression du
  /// navigateur ne verrait qu'une image de l'écran.
  print([
    SingleActivator(LogicalKeyboardKey.keyP, control: true),
    SingleActivator(LogicalKeyboardKey.keyP, meta: true),
  ]);

  const PageAction(this.activators);

  final List<ShortcutActivator> activators;
}

/// Lie [action] à [onInvoke] pour l'écran qui porte [child] (cf.
/// [RouteKeyShortcut] : une modale ouverte par-dessus garde ses touches).
///
/// [onInvoke] nul, ou [isAllowed] faux au moment de la touche (session gelée,
/// droit retiré), et la touche n'est pas prise : sur le web, F5 recharge
/// alors la page comme d'habitude.
///
/// Un même écran ne pose qu'un raccourci par geste : deux réponses à F5 se
/// déclencheraient toutes les deux.
class PageActionShortcut extends StatelessWidget {
  final PageAction action;
  final VoidCallback? onInvoke;
  final bool Function()? isAllowed;
  final Widget child;

  const PageActionShortcut({
    super.key,
    required this.action,
    required this.onInvoke,
    this.isAllowed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final onInvoke = this.onInvoke;
    if (onInvoke == null) return child;
    return RouteKeyShortcut(
      activators: action.activators,
      isEnabled: isAllowed,
      onPressed: onInvoke,
      child: child,
    );
  }
}
