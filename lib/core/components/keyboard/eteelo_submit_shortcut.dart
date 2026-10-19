import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/device/desktop_platform.dart';

/// Ctrl+Entrée (⌘+Entrée sur Mac) valide une modale de saisie, depuis
/// n'importe quel champ.
///
/// Pas Entrée seule : elle va à la ligne dans un champ multiligne et
/// enverrait la saisie à mi-phrase.
///
/// La modale prend le focus à l'ouverture. Sur la tablette, sans le donner à
/// un champ (le clavier virtuel ne s'ouvre pas) : le raccourci répond
/// aussitôt, et Tab mène au premier champ. Au clavier physique, le curseur
/// est posé dans le premier champ texte : on tape sans viser. Les champs
/// sont parcourus en groupe, sans fuir vers la page d'en dessous.
///
/// [onSubmit] nul (action principale désactivée) ⇒ le raccourci ne fait rien.
///
/// [onCancel] lie Échap à la fermeture : une modale ouverte avec
/// `barrierDismissible: false` (une saisie à ne pas perdre sur un clic à côté)
/// n'y répond pas d'elle-même — Flutter n'écoute Échap que si le scrim ferme.
/// Le geste vaut alors la croix de l'en-tête, rien de plus.
///
/// Hors modale (page, panneau en ligne), [autofocus] vaut `false` : le
/// raccourci répond dès que le focus est dans un des champs, sans le voler à
/// l'écran à l'ouverture.
class EteeloSubmitShortcut extends StatefulWidget {
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;
  final bool autofocus;
  final Widget child;

  const EteeloSubmitShortcut({
    super.key,
    required this.onSubmit,
    this.onCancel,
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

  static const ShortcutActivator cancelActivator = SingleActivator(
    LogicalKeyboardKey.escape,
    includeRepeats: false,
  );

  @override
  State<EteeloSubmitShortcut> createState() => _EteeloSubmitShortcutState();
}

class _EteeloSubmitShortcutState extends State<EteeloSubmitShortcut> {
  final _scope = FocusNode(skipTraversal: true);

  @override
  void initState() {
    super.initState();
    if (widget.autofocus && expectsPhysicalKeyboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusFirstField());
    }
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  /// Le premier champ texte de la modale, dans l'ordre de tabulation.
  void _focusFirstField() {
    if (!mounted) return;
    for (final node in _scope.traversalDescendants) {
      final editable = node.context
          ?.findAncestorStateOfType<EditableTextState>();
      if (editable != null && !editable.widget.readOnly) {
        node.requestFocus();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSubmit = widget.onSubmit;
    final onCancel = widget.onCancel;
    return CallbackShortcuts(
      bindings: {
        if (onSubmit != null)
          for (final activator in EteeloSubmitShortcut.activators)
            activator: onSubmit,
        EteeloSubmitShortcut.cancelActivator: ?onCancel,
      },
      child: Focus(
        focusNode: _scope,
        autofocus: widget.autofocus,
        child: FocusTraversalGroup(child: widget.child),
      ),
    );
  }
}
