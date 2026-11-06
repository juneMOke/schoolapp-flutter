import 'package:flutter/widgets.dart';

/// Une touche qui vaut pour tout un écran tant qu'aucun contrôle n'a le
/// focus — Espace pour déclencher une photo, par exemple.
///
/// Dès qu'un bouton est focalisé (Tab), la touche lui revient : Espace
/// active « Importer » au lieu de prendre une photo dans son dos. Un
/// `CallbackShortcuts` ne sait pas faire : posé au-dessus du bouton, il voit
/// la touche avant lui et la garde.
///
/// [autofocus] : le nœud de l'écran prend le focus à l'ouverture, pour que
/// la touche marche sans clic préalable. Le focus « libre » est ce nœud, ou
/// une portée (`FocusScope`) qui ne focalise aucun de ses enfants.
class IdleFocusShortcut extends StatefulWidget {
  final ShortcutActivator activator;
  final VoidCallback onInvoke;
  final bool autofocus;
  final Widget child;

  const IdleFocusShortcut({
    super.key,
    required this.activator,
    required this.onInvoke,
    required this.child,
    this.autofocus = false,
  });

  @override
  State<IdleFocusShortcut> createState() => _IdleFocusShortcutState();
}

class _IdleFocusShortcutState extends State<IdleFocusShortcut> {
  final FocusNode _node = FocusNode(debugLabel: 'IdleFocusShortcut');

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  bool _focusIsIdle() {
    final focused = FocusManager.instance.primaryFocus;
    return focused == null || focused == _node || focused is FocusScopeNode;
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {widget.activator: const _IdleIntent()},
      child: Actions(
        actions: {
          _IdleIntent: _IdleAction(
            isIdle: _focusIsIdle,
            onInvoke: () => widget.onInvoke(),
          ),
        },
        child: Focus(
          focusNode: _node,
          autofocus: widget.autofocus,
          child: widget.child,
        ),
      ),
    );
  }
}

class _IdleIntent extends Intent {
  const _IdleIntent();
}

/// Inactive quand un contrôle a le focus : la touche poursuit alors son
/// chemin jusqu'aux raccourcis de l'application, qui activent le contrôle.
class _IdleAction extends Action<_IdleIntent> {
  final bool Function() isIdle;
  final VoidCallback onInvoke;

  _IdleAction({required this.isIdle, required this.onInvoke});

  @override
  bool isEnabled(_IdleIntent intent) => isIdle();

  @override
  Object? invoke(_IdleIntent intent) {
    onInvoke();
    return null;
  }
}
