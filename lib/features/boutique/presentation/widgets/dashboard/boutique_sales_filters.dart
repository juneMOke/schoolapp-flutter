import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/sales_query.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_sales_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_family_style.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Type d'article **ou** classe — une bascule, puis le menu du mode actif.
///
/// La bascule rend l'exclusivité visible : un seul menu est à l'écran, donc un
/// seul critère peut partir. Deux menus côte à côte se liraient comme un
/// « et », que le serveur refuse.
class BoutiqueSalesFilters extends StatelessWidget {
  final BoutiqueSalesState state;
  final BoutiqueSalesCubit cubit;

  /// « Tous » se lit comme une valeur vide : le menu ne porte pas de `null`.
  static const String _all = '';
  static const double _selectWidth = 240;

  const BoutiqueSalesFilters({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppDimensions.spacingM,
      runSpacing: AppDimensions.spacingS,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        SegmentedTabFilter<SalesFilterMode>(
          selected: state.mode,
          onSelected: cubit.modeChanged,
          semanticsLabel: l10n.boutiqueSalesFilterSemantics,
          options: [
            SegmentedTabOption(
              label: l10n.boutiqueSalesFilterFamily,
              value: SalesFilterMode.family,
              icon: Icons.category_outlined,
            ),
            SegmentedTabOption(
              label: l10n.boutiqueSalesFilterClass,
              value: SalesFilterMode.classroom,
              icon: Icons.grid_view_rounded,
            ),
          ],
        ),
        SizedBox(
          width: _selectWidth,
          child: switch (state.mode) {
            SalesFilterMode.family => _familySelect(l10n),
            SalesFilterMode.classroom => _classSelect(l10n),
          },
        ),
      ],
    );
  }

  Widget _familySelect(AppLocalizations l10n) => EteeloSelectInput<String>(
    label: l10n.boutiqueSalesFilterFamily,
    value: state.family?.wire ?? _all,
    onChanged: (wire) => cubit.familySelected(ArticleFamily.fromWire(wire)),
    items: [
      EteeloSelectItem(value: _all, label: l10n.boutiqueSalesAllFamilies),
      for (final family in ArticleFamily.values)
        EteeloSelectItem(
          value: family.wire,
          label: BoutiqueFamilyStyle.labelOf(family, l10n),
        ),
    ],
  );

  Widget _classSelect(AppLocalizations l10n) {
    final classes = state.page?.classes ?? const [];
    final classId = state.classId;
    return EteeloSelectInput<String>(
      label: l10n.boutiqueSalesFilterClass,
      value: classId ?? _all,
      onChanged: (value) =>
          cubit.classSelected(value == null || value == _all ? null : value),
      items: [
        EteeloSelectItem(value: _all, label: l10n.boutiqueSalesAllClasses),
        for (final c in classes) EteeloSelectItem(value: c.id, label: c.label),
        // La classe choisie reste au menu même si cette période ne la porte
        // plus : le filtre actif doit se voir.
        if (classId != null && !classes.any((c) => c.id == classId))
          EteeloSelectItem(value: classId, label: state.classLabel ?? classId),
      ],
    );
  }
}
