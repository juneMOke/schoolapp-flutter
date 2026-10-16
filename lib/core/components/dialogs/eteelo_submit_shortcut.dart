import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Ctrl+Entrée (⌘+Entrée sur Mac) valide une modale de saisie, depuis
/// n'importe quel champ.
///
/// Pas Entrée seule : elle va à la ligne dans un champ multiligne et
/// enverrait la saisie à mi-phrase.
///
/// La modale prend le focus à l'ouverture, sans le donner à un champ (le
/// clavier virtuel d'une tablette ne s'ouvre pas) : le raccourci répond
/// aussitôt, et Tab mène au premier champ. Les champs sont parcourus en
/// groupe, sans fuir vers la page d'en dessous.
///
/// [onSubmit] nul (action principale désactivée) ⇒ le raccourci ne fait rien.
class EteeloSubmitShortcut extends StatelessWidget {
  final VoidCallback? onSubmit;
  final Widget child;

  const EteeloSubmitShortcut({
    super.key,
    required this.onSubmit,
    required this.child,
  });

  static const List<ShortcutActivator> activators = [
    SingleActivator(LogicalKeyboardKey.enter, control: true),
    SingleActivator(LogicalKeyboardKey.numpadEnter, control: true),
    SingleActivator(LogicalKeyboardKey.enter, meta: true),
  ];

  @override
  Widget build(BuildContext context) {
    final onSubmit = this.onSubmit;
    return CallbackShortcuts(
      bindings: {
        if (onSubmit != null)
          for (final activator in activators) activator: onSubmit,
      },
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        child: FocusTraversalGroup(child: child),
      ),
    );
  }
}
