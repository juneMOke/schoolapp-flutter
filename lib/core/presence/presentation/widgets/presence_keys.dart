import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_row_view.dart';

/// Le registre au clavier : une touche par statut, les flèches d'une personne
/// à l'autre. Faire l'appel d'une classe de soixante à la souris, c'est
/// soixante allers-retours entre la carte et le pied.
///
/// Actif dès que le focus est sur la carte ou la ligne (Tab, ou un clic) :
/// - **P** présent, **R** (ou **L**, *late*) en retard, **A** absent ;
/// - **Suppr** / **Retour arrière** remet « à pointer » ;
/// - **flèches** : la personne voisine — sur le web aussi, où elles feraient
///   sinon défiler la page.
///
/// Une touche pose son statut ; elle ne l'efface jamais. Contrairement au
/// toucher du segment, qui bascule, retaper « P » sur un présent ne fait rien :
/// au clavier, une frappe en trop ne doit pas défaire l'appel.
class PresenceKeys extends StatelessWidget {
  final PresenceRowView row;
  final PresenceRowActions actions;
  final Widget child;

  const PresenceKeys({
    super.key,
    required this.row,
    required this.actions,
    required this.child,
  });

  static const Map<ShortcutActivator, Intent> _arrows = {
    SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(
      TraversalDirection.down,
    ),
    SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(
      TraversalDirection.up,
    ),
    SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(
      TraversalDirection.left,
    ),
    SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(
      TraversalDirection.right,
    ),
  };

  void _mark(PresenceStatus status) {
    if (row.status != status) actions.choose(status);
  }

  void _clear() {
    if (row.status != PresenceStatus.none) actions.clear();
  }

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: _arrows,
    child: CallbackShortcuts(
      bindings: {
        const CharacterActivator('p'): () => _mark(PresenceStatus.present),
        const CharacterActivator('P'): () => _mark(PresenceStatus.present),
        const CharacterActivator('r'): () => _mark(PresenceStatus.late),
        const CharacterActivator('R'): () => _mark(PresenceStatus.late),
        const CharacterActivator('l'): () => _mark(PresenceStatus.late),
        const CharacterActivator('L'): () => _mark(PresenceStatus.late),
        const CharacterActivator('a'): () => _mark(PresenceStatus.absent),
        const CharacterActivator('A'): () => _mark(PresenceStatus.absent),
        const SingleActivator(LogicalKeyboardKey.delete): _clear,
        const SingleActivator(LogicalKeyboardKey.backspace): _clear,
      },
      child: child,
    ),
  );
}
