import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/home/domain/entity/menu_item.dart';

/// Barre repliée (rail) : les sous-menus d'un module s'ouvrent en menu
/// flottant à droite de son icône, au lieu de redéployer toute la barre — le
/// rail choisi pour gagner de la place le reste.
///
/// [builder] reçoit de quoi ouvrir / fermer le menu ; [onSelected] reçoit le
/// sous-menu choisi.
class SidebarRailFlyout extends StatelessWidget {
  final MenuItem menu;
  final ValueChanged<SubMenuItem> onSelected;
  final Widget Function(BuildContext context, VoidCallback toggle) builder;

  const SidebarRailFlyout({
    super.key,
    required this.menu,
    required this.onSelected,
    required this.builder,
  });

  /// L'encre d'un sous-menu inactif, celle de la barre déployée.
  static final _inactive = AppColors.textOnDark.withValues(alpha: 0.72);

  static const _style = MenuStyle(
    backgroundColor: WidgetStatePropertyAll(AppColors.surfaceDark),
    side: WidgetStatePropertyAll(BorderSide(color: AppColors.borderStrong)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: AppRadius.brMd),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: _style,
      menuChildren: [
        _Title(menu.title),
        for (final subMenu in menu.subMenus)
          MenuItemButton(
            onPressed: () => onSelected(subMenu),
            style: _itemStyle(selected: subMenu.isActive),
            child: Text(subMenu.title),
          ),
      ],
      builder: (context, controller, _) => builder(
        context,
        () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }

  static ButtonStyle _itemStyle({required bool selected}) => ButtonStyle(
    foregroundColor: WidgetStatePropertyAll(
      selected ? AppColors.textOnDark : _inactive,
    ),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) =>
          selected ||
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)
          ? AppColors.textOnDark.withValues(alpha: 0.09)
          : null,
    ),
    textStyle: const WidgetStatePropertyAll(AppTypography.bodyMedium),
  );
}

/// Le nom du module en tête du menu : l'icône seule ne le disait pas.
class _Title extends StatelessWidget {
  final String text;

  const _Title(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.sm,
      AppSpacing.md,
      AppSpacing.xs,
    ),
    child: Text(
      text.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: SidebarRailFlyout._inactive,
      ),
    ),
  );
}
