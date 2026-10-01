import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La ligne d'outils d'une collection de personnes : recherche, filtres
/// propres à l'écran ([filters]) et bascule cartes/liste facultative.
///
/// Le champ suit [text] : « Tout afficher » doit aussi le vider, sinon il
/// montrerait une recherche que le calcul ne connaît plus.
class EteeloSearchToolbar extends StatefulWidget {
  final String text;
  final String label;
  final String placeholder;
  final ValueChanged<String> onTextChanged;

  /// Les filtres de l'écran, posés entre la recherche et la bascule.
  final List<Widget> filters;

  /// `null` : pas de bascule cartes/liste.
  final ValueChanged<CollectionViewMode>? onViewModeChanged;
  final CollectionViewMode viewMode;

  const EteeloSearchToolbar({
    super.key,
    required this.text,
    required this.label,
    required this.placeholder,
    required this.onTextChanged,
    this.filters = const [],
    this.onViewModeChanged,
    this.viewMode = CollectionViewMode.grid,
  });

  @override
  State<EteeloSearchToolbar> createState() => _EteeloSearchToolbarState();
}

class _EteeloSearchToolbarState extends State<EteeloSearchToolbar> {
  late final TextEditingController _search = TextEditingController(
    text: widget.text,
  );

  @override
  void didUpdateWidget(covariant EteeloSearchToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _search.text) _search.text = widget.text;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onViewMode = widget.onViewModeChanged;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppDimensions.searchToolbarMinWidth,
            maxWidth: AppDimensions.searchToolbarMaxWidth,
          ),
          child: EteeloTextInput(
            controller: _search,
            label: widget.label,
            placeholder: widget.placeholder,
            capitalization: EteeloTextCapitalization.none,
            onChanged: widget.onTextChanged,
          ),
        ),
        ...widget.filters,
        if (onViewMode != null)
          SegmentedTabFilter<CollectionViewMode>(
            semanticsLabel: l10n.collectionViewLabel,
            selected: widget.viewMode,
            onSelected: onViewMode,
            options: [
              SegmentedTabOption(
                label: l10n.collectionViewGrid,
                value: CollectionViewMode.grid,
                icon: Icons.grid_view_outlined,
              ),
              SegmentedTabOption(
                label: l10n.collectionViewList,
                value: CollectionViewMode.list,
                icon: Icons.view_list_outlined,
              ),
            ],
          ),
      ],
    );
  }
}
