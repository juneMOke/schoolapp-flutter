import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_constants.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_decorations.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_field.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_panel_launcher.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_search.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_semantics.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_types.dart';

export 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_types.dart';

/// Le select de l'application.
///
/// Le champ fermé et le panneau ouvert sont deux pièces distinctes :
/// [EteeloSelectField] pour le repos, le focus et l'erreur ; un popover ancré
/// ou une feuille modale pour les options. Cette classe ne fait que les relier
/// — état du formulaire, arbitrage de la forme du panneau, retour du focus.
class EteeloSelectInput<T> extends StatefulWidget {
  final String label;
  final List<EteeloSelectItem<T>> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  /// Lecture seule : le champ est non interactif mais garde l'apparence d'un
  /// champ au repos (pleine couleur), contrairement à [enabled] = false qui
  /// grise le champ (repère « non disponible », ex. cascade en édition).
  final bool readOnly;
  final bool required;
  final String? errorText;

  /// Précision sous le champ, effacée par [errorText] quand il y en a un :
  /// une aide et une erreur empilées font lire l'aide comme une seconde erreur.
  final String? helperText;
  final String? placeholder;
  final String? Function(T?)? validator;
  final EteeloSelectPanelMode panelMode;
  final EteeloSelectDensity density;

  /// Ton du texte de substitution — voir [EteeloSelectPlaceholderTone].
  final EteeloSelectPlaceholderTone placeholderTone;

  /// Masque le libellé au-dessus du champ sans le perdre : il continue de
  /// nommer le champ pour les lecteurs d'écran et de titrer la feuille modale.
  /// Réservé aux sélecteurs déjà nommés par leur contexte (ligne de panier,
  /// barre de tri précédée de « Trier »).
  final bool hideLabel;

  /// Prend le focus à l'apparition. Réservé aux champs qu'un geste vient de
  /// faire naître et qui attendent une réponse immédiate (le motif d'absence,
  /// dès qu'un élève est coché absent).
  final bool autofocus;

  /// Force la recherche dans le panneau. Par défaut, elle apparaît d'elle-même
  /// au-delà de [EteeloSelectConstants.searchThreshold] options.
  final bool? searchable;
  final double minWidth;
  final double? menuMaxHeight;
  final Widget Function(
    BuildContext context,
    EteeloSelectItem<T> item,
    bool isSelected,
  )?
  itemBuilder;
  final Widget Function(BuildContext context, EteeloSelectItem<T> item)?
  selectedItemBuilder;

  const EteeloSelectInput({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.required = false,
    this.errorText,
    this.helperText,
    this.placeholder,
    this.validator,
    this.panelMode = EteeloSelectPanelMode.adaptive,
    this.density = EteeloSelectDensity.standard,
    this.placeholderTone = EteeloSelectPlaceholderTone.muted,
    this.hideLabel = false,
    this.autofocus = false,
    this.searchable,
    this.minWidth = 180,
    this.menuMaxHeight,
    this.itemBuilder,
    this.selectedItemBuilder,
  });

  @override
  State<EteeloSelectInput<T>> createState() => _EteeloSelectInputState<T>();
}

class _EteeloSelectInputState<T> extends State<EteeloSelectInput<T>> {
  final _fieldKey = GlobalKey();

  late final FocusNode _focusNode;
  bool _isPanelOpen = false;

  // Interactif uniquement si activé ET pas en lecture seule.
  bool get _interactive => widget.enabled && !widget.readOnly;

  // Grisé (repère « non disponible ») uniquement si désactivé ET pas en
  // lecture seule : la lecture seule garde l'apparence pleine couleur.
  bool get _dimmed => !widget.enabled && !widget.readOnly;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  EteeloSelectItem<T>? _selectedItem(T? value) {
    if (value == null) return null;
    for (final item in widget.items) {
      if (item.value == value) return item;
    }
    return null;
  }

  Rect? _anchorRect() {
    final box = _fieldKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _openPanel(FormFieldState<T> state) async {
    if (!_interactive || _isPanelOpen) return;

    final items = dedupeSelectItems(widget.items);
    final searchable =
        widget.searchable ??
        items.length >= EteeloSelectConstants.searchThreshold;

    setState(() => _isPanelOpen = true);

    final result = await openEteeloSelectPanel<T>(
      context: context,
      mode: resolveEteeloSelectPanelMode(context, widget.panelMode),
      anchorRect: _anchorRect(),
      items: items,
      selectedValue: state.value,
      title: widget.label,
      searchable: searchable,
      maxHeight: widget.menuMaxHeight,
      itemBuilder: widget.itemBuilder,
    );

    if (!mounted) return;
    setState(() => _isPanelOpen = false);

    if (result != null && result != state.value) {
      state.didChange(result);
      widget.onChanged(result);
    }
    _focusNode.requestFocus();
  }

  KeyEventResult _handleFieldKey(FormFieldState<T> state, KeyEvent event) {
    if (event is! KeyDownEvent || !_interactive || _isPanelOpen) {
      return KeyEventResult.ignored;
    }
    // Les touches qui ouvrent une liste : valider, espacer, ou descendre
    // dedans. Comparaisons explicites — `LogicalKeyboardKey` redéfinit `==`,
    // il n'a donc sa place ni dans un `const Set` ni dans un motif constant.
    final key = event.logicalKey;
    final opens =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.arrowDown;
    if (!opens) return KeyEventResult.ignored;
    _openPanel(state);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: widget.minWidth),
      child: FormField<T>(
        initialValue: widget.value,
        validator: widget.validator,
        builder: (state) {
          final currentValue = widget.value;
          if (state.value != currentValue) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) state.didChange(currentValue);
            });
          }

          final selectedItem = _selectedItem(state.value);
          final resolvedErrorText = widget.errorText ?? state.errorText;
          final placeholder = resolveSelectPlaceholder(
            context,
            widget.placeholder,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.hideLabel) ...[
                ExcludeSemantics(
                  child: EteeloSelectLabel(
                    label: widget.label,
                    required: widget.required,
                  ),
                ),
                const SizedBox(height: EteeloSelectConstants.labelGap),
              ],
              _buildField(
                state: state,
                selectedItem: selectedItem,
                placeholder: placeholder,
                hasError: resolvedErrorText?.isNotEmpty ?? false,
              ),
              ..._buildFootnote(resolvedErrorText),
            ],
          );
        },
      ),
    );
  }

  Widget _buildField({
    required FormFieldState<T> state,
    required EteeloSelectItem<T>? selectedItem,
    required String placeholder,
    required bool hasError,
  }) {
    final semanticLabel = resolveSelectSemanticLabel(
      context,
      widget.label,
      widget.required,
    );

    return Semantics(
      label: semanticLabel,
      value: selectedItem?.label ?? placeholder,
      button: true,
      enabled: _interactive,
      readOnly: widget.readOnly,
      focused: _focusNode.hasFocus,
      child: Focus(
        focusNode: _focusNode,
        canRequestFocus: _interactive,
        autofocus: widget.autofocus && _interactive,
        onKeyEvent: (_, event) => _handleFieldKey(state, event),
        child: EteeloSelectField(
          key: _fieldKey,
          selectedLabel: selectedItem?.label,
          selectedContent: selectedItem == null
              ? null
              : widget.selectedItemBuilder?.call(context, selectedItem),
          placeholder: placeholder,
          isOpen: _isPanelOpen,
          hasFocus: _interactive && _focusNode.hasFocus,
          dimmed: _dimmed,
          hasError: hasError,
          density: widget.density,
          placeholderTone: widget.placeholderTone,
          onTap: _interactive ? () => _openPanel(state) : null,
        ),
      ),
    );
  }

  List<Widget> _buildFootnote(String? resolvedErrorText) {
    if (!EteeloSelectFootnote.hasContent(
      errorText: resolvedErrorText,
      helperText: widget.helperText,
    )) {
      return const [];
    }
    return [
      const SizedBox(height: AppSpacing.xs),
      ExcludeSemantics(
        child: EteeloSelectFootnote(
          errorText: resolvedErrorText,
          helperText: widget.helperText,
        ),
      ),
    ];
  }
}
