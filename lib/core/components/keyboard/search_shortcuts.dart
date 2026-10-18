import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/components/keyboard/route_key_shortcut.dart';

/// Ctrl+F (⌘+F) ou « / » placent le curseur dans la recherche de l'écran,
/// où que soit le focus — comme dans un navigateur ou une messagerie.
///
/// Le premier champ texte de [child] reçoit le focus : la recherche n'a pas à
/// exposer son `FocusNode`. « / » s'écrit normalement dans un champ déjà
/// actif ; Ctrl+F, lui, y répond aussi (passer d'un filtre à la recherche).
///
/// Sur le web, Ctrl+F remplace la recherche du navigateur — qui ne voit de
/// toute façon pas le texte dessiné par Flutter.
class SearchFocusShortcut extends StatefulWidget {
  final Widget child;

  const SearchFocusShortcut({super.key, required this.child});

  static const List<ShortcutActivator> findActivators = [
    SingleActivator(LogicalKeyboardKey.keyF, control: true),
    SingleActivator(LogicalKeyboardKey.keyF, meta: true),
  ];

  /// Le caractère, pas la touche : « / » est Maj+« : » sur un clavier AZERTY.
  static const List<ShortcutActivator> slashActivators = [
    CharacterActivator('/'),
  ];

  @override
  State<SearchFocusShortcut> createState() => _SearchFocusShortcutState();
}

class _SearchFocusShortcutState extends State<SearchFocusShortcut> {
  final _anchor = FocusNode(
    debugLabel: 'SearchFocusShortcut',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void dispose() {
    _anchor.dispose();
    super.dispose();
  }

  void _focusSearch() {
    final field = _anchor.traversalDescendants.firstOrNull;
    if (field == null) return;
    field.requestFocus();
    // Tout le texte sélectionné : la frappe suivante remplace la recherche
    // précédente au lieu de s'y ajouter.
    final editable = field.context
        ?.findAncestorStateOfType<EditableTextState>();
    final value = editable?.textEditingValue;
    if (editable != null && value != null && value.text.isNotEmpty) {
      editable.userUpdateTextEditingValue(
        value.copyWith(
          selection: TextSelection(
            baseOffset: 0,
            extentOffset: value.text.length,
          ),
        ),
        SelectionChangedCause.keyboard,
      );
    }
  }

  @override
  Widget build(BuildContext context) => RouteKeyShortcut(
    activators: SearchFocusShortcut.findActivators,
    onPressed: _focusSearch,
    child: RouteKeyShortcut(
      activators: SearchFocusShortcut.slashActivators,
      ignoreWhileTyping: true,
      onPressed: _focusSearch,
      child: Focus(focusNode: _anchor, child: widget.child),
    ),
  );
}

/// Échap vide le champ de recherche qui a le focus.
///
/// Champ déjà vide : Échap n'est pas consommée et garde son sens ordinaire
/// (fermer la modale, replier le menu).
class ClearOnEscape extends StatelessWidget {
  final TextEditingController controller;

  /// Prévenu après l'effacement, comme le serait une saisie : le filtre en
  /// direct doit suivre le champ.
  final ValueChanged<String>? onCleared;
  final Widget child;

  const ClearOnEscape({
    super.key,
    required this.controller,
    this.onCleared,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.escape): _ClearSearchIntent(),
    },
    child: Actions(
      actions: {_ClearSearchIntent: _ClearSearchAction(controller, onCleared)},
      child: child,
    ),
  );
}

class _ClearSearchIntent extends Intent {
  const _ClearSearchIntent();
}

class _ClearSearchAction extends Action<_ClearSearchIntent> {
  final TextEditingController controller;
  final ValueChanged<String>? onCleared;

  _ClearSearchAction(this.controller, this.onCleared);

  /// Désactivée ⇒ la touche n'est pas consommée et remonte.
  @override
  bool isEnabled(_ClearSearchIntent intent) => controller.text.isNotEmpty;

  @override
  Object? invoke(_ClearSearchIntent intent) {
    controller.clear();
    onCleared?.call('');
    return null;
  }
}
