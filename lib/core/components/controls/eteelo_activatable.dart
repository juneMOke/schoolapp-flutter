import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Ce qu'une zone activable montre d'elle-même : le survol de la souris et le
/// focus clavier. Le focus n'est vrai qu'en navigation au clavier — un tap ne
/// l'allume pas.
@immutable
class ActivatableHighlight {
  final bool hovered;
  final bool focused;

  const ActivatableHighlight({this.hovered = false, this.focused = false});

  bool get any => hovered || focused;
}

/// Une zone cliquable maison qui se comporte comme un bouton sur desktop et
/// sur le web : curseur main, une seule étape de tabulation, Entrée et Espace
/// l'activent, et le survol comme le focus sont rendus à [builder].
///
/// [onActivate] nul ⇒ la zone est inerte : ni focus, ni curseur, ni tap.
///
/// Le [builder] ne doit contenir aucun autre élément focalisable (`InkWell`,
/// bouton) : il ajouterait une seconde étape de tabulation que rien n'active.
class EteeloActivatable extends StatefulWidget {
  final VoidCallback? onActivate;
  final Widget Function(BuildContext context, ActivatableHighlight highlight)
  builder;
  final FocusNode? focusNode;
  final bool autofocus;

  const EteeloActivatable({
    super.key,
    required this.onActivate,
    required this.builder,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<EteeloActivatable> createState() => _EteeloActivatableState();
}

class _EteeloActivatableState extends State<EteeloActivatable> {
  /// Explicites : sur le web, Espace défile par défaut au lieu d'activer.
  static const Map<ShortcutActivator, Intent> _shortcuts = {
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
  };

  bool _hovered = false;
  bool _focused = false;

  void _activate() => widget.onActivate?.call();

  void _setHovered(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onActivate != null;
    return FocusableActionDetector(
      enabled: enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      shortcuts: _shortcuts,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _activate();
            return null;
          },
        ),
      },
      onShowFocusHighlight: (value) {
        if (_focused != value) setState(() => _focused = value);
      },
      // Le survol se lit sur la souris elle-même, pas sur le mode de
      // surbrillance : une tablette à souris branchée reste en mode
      // « tactile » tant qu'on n'a pas cliqué.
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? _activate : null,
          child: widget.builder(
            context,
            ActivatableHighlight(
              hovered: enabled && _hovered,
              focused: enabled && _focused,
            ),
          ),
        ),
      ),
    );
  }
}
