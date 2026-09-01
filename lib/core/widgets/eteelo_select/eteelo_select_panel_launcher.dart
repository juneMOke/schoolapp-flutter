import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_popover.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_sheet.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_types.dart';

/// Popover ou feuille : arbitré à l'OUVERTURE, pas à la construction — une
/// tablette qu'on tourne entre deux ouvertures change la forme du panneau
/// suivant, jamais celle du panneau en cours.
EteeloSelectPanelMode resolveEteeloSelectPanelMode(
  BuildContext context,
  EteeloSelectPanelMode requested,
) {
  if (requested != EteeloSelectPanelMode.adaptive) return requested;
  return MediaQuery.sizeOf(context).width >= AppBreakpoints.selectPopoverMin
      ? EteeloSelectPanelMode.popover
      : EteeloSelectPanelMode.sheet;
}

/// Ouvre le panneau d'options et rend le choix, ou `null` si l'utilisateur
/// est ressorti sans choisir.
///
/// [anchorRect] est la position du champ à l'écran ; absente (champ pas encore
/// mesuré), on retombe sur la feuille, qui n'a besoin d'aucun ancrage.
Future<T?> openEteeloSelectPanel<T>({
  required BuildContext context,
  required EteeloSelectPanelMode mode,
  required Rect? anchorRect,
  required List<EteeloSelectItem<T>> items,
  required T? selectedValue,
  required String title,
  required bool searchable,
  double? maxHeight,
  Widget Function(
    BuildContext context,
    EteeloSelectItem<T> item,
    bool isSelected,
  )?
  itemBuilder,
}) {
  if (mode == EteeloSelectPanelMode.popover && anchorRect != null) {
    return showEteeloSelectPopover<T>(
      context: context,
      anchorRect: anchorRect,
      items: items,
      selectedValue: selectedValue,
      searchable: searchable,
      maxHeight: maxHeight,
      itemBuilder: itemBuilder,
    );
  }
  return showEteeloSelectSheet<T>(
    context: context,
    items: items,
    selectedValue: selectedValue,
    title: title,
    searchable: searchable,
    itemBuilder: itemBuilder,
  );
}
