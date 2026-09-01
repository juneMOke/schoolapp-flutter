import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_constants.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_panel_body.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_types.dart';

/// Ouvre le panneau d'options en feuille modale (petits écrans).
///
/// [title] reprend le libellé du champ : la feuille couvre le formulaire, et
/// sans rappel de ce qu'on renseigne, une liste de communes ne dit pas
/// d'elle-même si on saisit le lieu de naissance ou l'adresse.
Future<T?> showEteeloSelectSheet<T>({
  required BuildContext context,
  required List<EteeloSelectItem<T>> items,
  required T? selectedValue,
  required String title,
  required bool searchable,
  Widget Function(
    BuildContext context,
    EteeloSelectItem<T> item,
    bool isSelected,
  )?
  itemBuilder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    useRootNavigator: true,
    // Le clavier de la recherche ne doit pas pousser la liste hors de l'écran :
    // la feuille se redimensionne au lieu de glisser.
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    constraints: const BoxConstraints(
      maxWidth: EteeloSelectConstants.sheetMaxWidth,
    ),
    builder: (sheetContext) => _EteeloSelectSheetBody<T>(
      items: items,
      selectedValue: selectedValue,
      title: title,
      searchable: searchable,
      itemBuilder: itemBuilder,
    ),
  );
}

class _EteeloSelectSheetBody<T> extends StatelessWidget {
  final List<EteeloSelectItem<T>> items;
  final T? selectedValue;
  final String title;
  final bool searchable;
  final Widget Function(
    BuildContext context,
    EteeloSelectItem<T> item,
    bool isSelected,
  )?
  itemBuilder;

  const _EteeloSelectSheetBody({
    required this.items,
    required this.selectedValue,
    required this.title,
    required this.searchable,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight =
        media.size.height * EteeloSelectConstants.sheetMaxHeightFactor;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  title,
                  style: AppTypography.labelFormLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: EteeloSelectPanelBody<T>(
                    items: items,
                    selectedValue: selectedValue,
                    searchable: searchable,
                    // Sur téléphone, ouvrir le clavier d'emblée mangerait la
                    // moitié de la feuille : la recherche attend qu'on la
                    // touche, la liste reste la première chose visible.
                    autofocusSearch: false,
                    itemBuilder: itemBuilder,
                    onSelected: (value) => Navigator.of(context).pop<T>(value),
                    onDismiss: () => Navigator.of(context).pop<T>(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
