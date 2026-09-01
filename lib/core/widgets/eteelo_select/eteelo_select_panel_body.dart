import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_constants.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_option_tile.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_search_field.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_search.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_types.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Contenu du panneau d'options, partagé par le popover ancré et la feuille
/// modale : une seule liste, une seule recherche, un seul comportement clavier.
/// La forme change avec l'écran, jamais ce qu'on peut y faire.
class EteeloSelectPanelBody<T> extends StatefulWidget {
  final List<EteeloSelectItem<T>> items;
  final T? selectedValue;
  final bool searchable;
  final bool autofocusSearch;
  final ValueChanged<T> onSelected;
  final VoidCallback onDismiss;
  final Widget Function(
    BuildContext context,
    EteeloSelectItem<T> item,
    bool isSelected,
  )?
  itemBuilder;

  const EteeloSelectPanelBody({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.searchable,
    required this.autofocusSearch,
    required this.onSelected,
    required this.onDismiss,
    this.itemBuilder,
  });

  @override
  State<EteeloSelectPanelBody<T>> createState() =>
      _EteeloSelectPanelBodyState<T>();
}

class _EteeloSelectPanelBodyState<T> extends State<EteeloSelectPanelBody<T>> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();

  late List<EteeloSelectItem<T>> _visible;
  int _highlighted = -1;

  @override
  void initState() {
    super.initState();
    _visible = widget.items;
    _highlighted = _indexOfSelected();
    // La liste ouvre SUR le choix courant, pas en tête : sur 195 nationalités,
    // rouvrir le champ pour vérifier ce qui est enregistré ne doit pas
    // redemander de faire défiler jusqu'à la lettre.
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealHighlight());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _indexOfSelected() {
    final value = widget.selectedValue;
    if (value == null) return _visible.isEmpty ? -1 : 0;
    final index = _visible.indexWhere((item) => item.value == value);
    return index >= 0 ? index : (_visible.isEmpty ? -1 : 0);
  }

  void _onQueryChanged(String query) {
    setState(() {
      _visible = filterSelectItems(widget.items, query);
      _highlighted = _indexOfSelected();
    });
    _revealHighlight();
  }

  /// Hauteur estimée d'une ligne — sous-titre compris. Sert uniquement à
  /// amener la ligne visée sous l'œil ; une erreur de quelques pixels décale
  /// le centrage, elle ne casse rien.
  double _offsetOf(int index) {
    var offset = 0.0;
    for (var i = 0; i < index && i < _visible.length; i++) {
      final hasSubtitle = _visible[i].subtitle?.isNotEmpty ?? false;
      offset +=
          EteeloSelectConstants.optionMinHeight +
          EteeloSelectConstants.optionGap +
          (hasSubtitle ? AppSpacing.lg : 0);
    }
    return offset;
  }

  void _revealHighlight() {
    if (!mounted || _highlighted < 0 || !_scrollController.hasClients) return;
    final viewport = _scrollController.position.viewportDimension;
    final target =
        (_offsetOf(_highlighted) -
                viewport / 2 +
                EteeloSelectConstants.optionMinHeight / 2)
            .clamp(
              _scrollController.position.minScrollExtent,
              _scrollController.position.maxScrollExtent,
            );
    _scrollController.jumpTo(target);
  }

  void _moveHighlight(int delta) {
    if (_visible.isEmpty) return;
    var next = _highlighted;
    for (var step = 0; step < _visible.length; step++) {
      next = (next + delta).clamp(0, _visible.length - 1);
      if (_visible[next].enabled) break;
      if (next == 0 || next == _visible.length - 1) break;
    }
    if (next == _highlighted) return;
    setState(() => _highlighted = next);
    _revealHighlight();
  }

  void _selectHighlighted() {
    if (_highlighted < 0 || _highlighted >= _visible.length) return;
    final item = _visible[_highlighted];
    if (!item.enabled) return;
    widget.onSelected(item.value);
  }

  @override
  Widget build(BuildContext context) {
    // `CallbackShortcuts` posé ICI, au-dessus du champ de recherche : les
    // raccourcis d'édition de texte de Flutter vivent à la racine de
    // l'application, donc le nœud le plus proche du focus gagne. C'est ce qui
    // rend les flèches disponibles pour parcourir la liste au lieu de
    // déplacer le curseur dans la recherche.
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _moveHighlight(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _moveHighlight(-1),
        const SingleActivator(LogicalKeyboardKey.enter): _selectHighlighted,
        const SingleActivator(LogicalKeyboardKey.numpadEnter):
            _selectHighlighted,
        const SingleActivator(LogicalKeyboardKey.escape): widget.onDismiss,
      },
      child: Focus(
        // Quelque chose DOIT avoir le focus dans le panneau, sinon les flèches
        // n'ont personne à qui parler. Quand la recherche ne le prend pas
        // (liste courte, ou plateforme tactile où le clavier logiciel
        // monterait), c'est le panneau lui-même qui le porte.
        autofocus: !(widget.searchable && widget.autofocusSearch),
        skipTraversal: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.searchable) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  EteeloSelectConstants.panelPadding,
                  EteeloSelectConstants.panelPadding,
                  EteeloSelectConstants.panelPadding,
                  0,
                ),
                child: EteeloSelectSearchField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  autofocus: widget.autofocusSearch,
                  onChanged: _onQueryChanged,
                ),
              ),
              const SizedBox(height: EteeloSelectConstants.panelPadding),
              const Divider(height: 1, color: AppColors.border),
            ],
            Flexible(
              child: _visible.isEmpty ? _buildEmpty(context) : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      controller: _scrollController,
      shrinkWrap: true,
      padding: const EdgeInsets.all(EteeloSelectConstants.panelPadding),
      itemCount: _visible.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: EteeloSelectConstants.optionGap),
      itemBuilder: (context, index) {
        final item = _visible[index];
        final isSelected = item.value == widget.selectedValue;
        return EteeloSelectOptionTile<T>(
          item: item,
          isSelected: isSelected,
          isHighlighted: index == _highlighted,
          content: widget.itemBuilder?.call(context, item, isSelected),
          onTap: item.enabled ? () => widget.onSelected(item.value) : null,
        );
      },
    );
  }

  /// État vide « en ligne », et non le médaillon `EteeloEmptyResult` : celui-ci
  /// réclame 380 dp de haut quand le panneau en fait 320 au total. La règle des
  /// états partagés vise une zone de résultats, pas la réponse d'un filtre.
  Widget _buildEmpty(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasQuery = _searchController.text.trim().isNotEmpty;
    final message = hasQuery
        ? l10n?.selectNoOptionMatches
        : l10n?.selectNoOptionAvailable;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: EteeloSelectConstants.optionIconSize,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              message ?? '',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
