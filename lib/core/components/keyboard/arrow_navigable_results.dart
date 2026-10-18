import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Liste de résultats parcourue aux flèches : ↑/↓ passent d'une ligne à
/// l'autre, Entrée choisit (la ligne est un bouton), ↑ depuis la première
/// remonte vers le formulaire.
///
/// Sans elle, il faut une tabulation par ligne — et sur le web, les flèches
/// font défiler la page au lieu de déplacer le focus.
///
/// [anchor] est partagé avec [SearchToResultsShortcut] : c'est par lui que ↓,
/// depuis un champ de recherche, trouve la première ligne.
class ArrowNavigableResults extends StatelessWidget {
  final FocusNode anchor;
  final Widget child;

  const ArrowNavigableResults({
    super.key,
    required this.anchor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: anchor,
    canRequestFocus: false,
    skipTraversal: true,
    child: Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(
          TraversalDirection.down,
        ),
        SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(
          TraversalDirection.up,
        ),
      },
      child: FocusTraversalGroup(child: child),
    ),
  );
}

/// ↓ depuis le formulaire de recherche descend sur la première ligne des
/// résultats liés à [anchor].
///
/// Sans résultat, la touche n'est pas consommée : elle garde son sens dans le
/// champ.
class SearchToResultsShortcut extends StatelessWidget {
  final FocusNode anchor;
  final Widget child;

  const SearchToResultsShortcut({
    super.key,
    required this.anchor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.arrowDown): _EnterResultsIntent(),
    },
    child: Actions(
      actions: {_EnterResultsIntent: _EnterResultsAction(anchor)},
      child: child,
    ),
  );
}

class _EnterResultsIntent extends Intent {
  const _EnterResultsIntent();
}

class _EnterResultsAction extends Action<_EnterResultsIntent> {
  final FocusNode anchor;

  _EnterResultsAction(this.anchor);

  @override
  bool isEnabled(_EnterResultsIntent intent) =>
      !anchor.hasFocus && anchor.traversalDescendants.isNotEmpty;

  @override
  Object? invoke(_EnterResultsIntent intent) {
    anchor.traversalDescendants.firstOrNull?.requestFocus();
    return null;
  }
}
