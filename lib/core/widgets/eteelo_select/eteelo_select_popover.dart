import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_panel_body.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_popover_layout.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_types.dart';

/// Ouvre le panneau d'options **ancré** sous le champ.
///
/// [anchorRect] est en coordonnées écran (`localToGlobal`) : la route est
/// poussée sur le navigateur racine pour passer au-dessus d'une éventuelle
/// modale hôte, dont l'overlay couvre le même repère.
Future<T?> showEteeloSelectPopover<T>({
  required BuildContext context,
  required Rect anchorRect,
  required List<EteeloSelectItem<T>> items,
  required T? selectedValue,
  required bool searchable,
  double? maxHeight,
  Widget Function(
    BuildContext context,
    EteeloSelectItem<T> item,
    bool isSelected,
  )?
  itemBuilder,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    _EteeloSelectPopoverRoute<T>(
      anchorRect: anchorRect,
      items: items,
      selectedValue: selectedValue,
      searchable: searchable,
      maxHeight: maxHeight,
      itemBuilder: itemBuilder,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: Navigator.of(context, rootNavigator: true).context,
      ),
    ),
  );
}

class _EteeloSelectPopoverRoute<T> extends PopupRoute<T> {
  final Rect anchorRect;
  final List<EteeloSelectItem<T>> items;
  final T? selectedValue;
  final bool searchable;
  final double? maxHeight;
  final Widget Function(
    BuildContext context,
    EteeloSelectItem<T> item,
    bool isSelected,
  )?
  itemBuilder;
  final CapturedThemes capturedThemes;

  _EteeloSelectPopoverRoute({
    required this.anchorRect,
    required this.items,
    required this.selectedValue,
    required this.searchable,
    required this.maxHeight,
    required this.itemBuilder,
    required this.barrierLabel,
    required this.capturedThemes,
  });

  @override
  final String? barrierLabel;

  /// Aucun voile : le panneau se pose SUR le formulaire, il ne le remplace
  /// pas. Assombrir l'écran pour choisir un cycle ferait perdre de vue les
  /// champs déjà remplis qui motivent le choix.
  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => AppMotion.medium;

  @override
  Duration get reverseTransitionDuration => AppMotion.fast;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Builder(
      builder: (context) {
        final media = MediaQuery.of(context);
        return CustomSingleChildLayout(
          delegate: EteeloSelectPopoverLayout(
            anchorRect: anchorRect,
            viewInsets: media.viewInsets,
            maxHeight: maxHeight,
          ),
          child: capturedThemes.wrap(
            _EteeloSelectPopoverPanel<T>(
              items: items,
              selectedValue: selectedValue,
              searchable: searchable,
              itemBuilder: itemBuilder,
              onSelected: (value) => Navigator.of(context).pop<T>(value),
              onDismiss: () => Navigator.of(context).pop<T>(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.outCurve,
      reverseCurve: AppMotion.inCurve,
    );
    return FadeTransition(
      opacity: curved,
      // Le panneau « descend » du champ au lieu d'apparaître : le lien entre
      // la liste et le champ qui l'a ouverte se lit dans le mouvement.
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class _EteeloSelectPopoverPanel<T> extends StatelessWidget {
  final List<EteeloSelectItem<T>> items;
  final T? selectedValue;
  final bool searchable;
  final ValueChanged<T> onSelected;
  final VoidCallback onDismiss;
  final Widget Function(
    BuildContext context,
    EteeloSelectItem<T> item,
    bool isSelected,
  )?
  itemBuilder;

  const _EteeloSelectPopoverPanel({
    required this.items,
    required this.selectedValue,
    required this.searchable,
    required this.onSelected,
    required this.onDismiss,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.shadowRaised,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: EteeloSelectPanelBody<T>(
          items: items,
          selectedValue: selectedValue,
          searchable: searchable,
          // La recherche prend le focus là où le clavier est déjà là (poste
          // fixe, web). Sur une tablette, ce serait le clavier logiciel qui
          // monterait d'office et mangerait la liste qu'on vient d'ouvrir :
          // il attend qu'on touche la barre.
          autofocusSearch: switch (defaultTargetPlatform) {
            TargetPlatform.android || TargetPlatform.iOS => false,
            _ => true,
          },
          itemBuilder: itemBuilder,
          onSelected: onSelected,
          onDismiss: onDismiss,
        ),
      ),
    );
  }
}
