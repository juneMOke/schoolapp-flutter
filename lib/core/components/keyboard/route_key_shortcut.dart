import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Un raccourci clavier qui vaut pour tout un écran, que le focus soit dans
/// un champ, sur un bouton, ou nulle part.
///
/// Un `CallbackShortcuts` posé dans la page ne voit rien tant qu'aucun de ses
/// descendants n'a le focus — or, à l'ouverture d'une route, le focus est sur
/// la route elle-même, au-dessus de la page. On écoute donc le clavier
/// matériel, et on n'agit que si la route qui porte [child] est au premier
/// plan : une modale ouverte par-dessus garde ses touches. Un écran gardé en
/// vie hors champ (onglet d'un `IndexedStack`) ne répond pas non plus.
class RouteKeyShortcut extends StatefulWidget {
  final List<ShortcutActivator> activators;
  final VoidCallback onPressed;
  final Widget child;

  /// Laisse passer la touche quand un champ texte a le focus : une touche
  /// imprimable (« / ») doit s'y écrire, pas déclencher le raccourci.
  final bool ignoreWhileTyping;

  const RouteKeyShortcut({
    super.key,
    required this.activators,
    required this.onPressed,
    required this.child,
    this.ignoreWhileTyping = false,
  });

  @override
  State<RouteKeyShortcut> createState() => _RouteKeyShortcutState();
}

class _RouteKeyShortcutState extends State<RouteKeyShortcut> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handle);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handle);
    super.dispose();
  }

  bool _handle(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    if (!TickerMode.valuesOf(context).enabled) return false;
    if (widget.ignoreWhileTyping && isEditingText) return false;
    final keyboard = HardwareKeyboard.instance;
    for (final activator in widget.activators) {
      if (activator.accepts(event, keyboard)) {
        widget.onPressed();
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Vrai quand le focus est dans un champ texte.
bool get isEditingText =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorStateOfType<EditableTextState>() !=
    null;
