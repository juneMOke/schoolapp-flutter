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
///
/// Hors modale (page, panneau en ligne), [autofocus] vaut `false` : le
/// raccourci répond dès que le focus est dans un des champs, sans le voler à
/// l'écran à l'ouverture.
class EteeloSubmitShortcut extends StatelessWidget {
  final VoidCallback? onSubmit;
  final bool autofocus;
  final Widget child;

  const EteeloSubmitShortcut({
    super.key,
    required this.onSubmit,
    this.autofocus = true,
    required this.child,
  });

  /// Sans répétition : Ctrl+Entrée maintenue n'envoie qu'une fois.
  static const List<ShortcutActivator> activators = [
    SingleActivator(
      LogicalKeyboardKey.enter,
      control: true,
      includeRepeats: false,
    ),
    SingleActivator(
      LogicalKeyboardKey.numpadEnter,
      control: true,
      includeRepeats: false,
    ),
    SingleActivator(
      LogicalKeyboardKey.enter,
      meta: true,
      includeRepeats: false,
    ),
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
        autofocus: autofocus,
        skipTraversal: true,
        child: FocusTraversalGroup(child: child),
      ),
    );
  }
}
