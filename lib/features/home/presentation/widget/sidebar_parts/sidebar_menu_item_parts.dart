import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/home/domain/entity/menu_item.dart'
    as domain;
import 'package:school_app_flutter/features/home/presentation/widget/home_navigation_ui_tokens.dart';

/// Rangée de contenu pour un module en mode déployé (icône + libellé + chevron).
class SidebarMenuItemExpandedRow extends StatelessWidget {
  final domain.MenuItem menu;
  final bool isActive;
  final bool isMenuOpened;
  final bool canShowText;

  const SidebarMenuItemExpandedRow({
    super.key,
    required this.menu,
    required this.isActive,
    required this.isMenuOpened,
    required this.canShowText,
  });

  @override
  Widget build(BuildContext context) {
    final activeForeground = AppColors.textOnDark;
    final inactiveForeground = AppColors.textOnDark.withValues(alpha: 0.72);
    final iconColor = isActive ? activeForeground : inactiveForeground;

    return Row(
      key: ValueKey<String>('menu-expanded-${menu.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(menu.icon, color: iconColor, size: 22),
        if (canShowText) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              menu.title,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: TextStyle(
                color: iconColor,
                fontSize: HomeNavigationUiTokens.topBarTitleFontSize - 5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          if (menu.subMenus.isNotEmpty)
            Icon(
              isMenuOpened
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: iconColor,
              size: 18,
            ),
        ],
      ],
    );
  }
}

/// Icône seule avec tooltip pour un module en mode rail (replié).
class SidebarMenuItemCollapsedIcon extends StatelessWidget {
  final domain.MenuItem menu;
  final bool isActive;

  const SidebarMenuItemCollapsedIcon({
    super.key,
    required this.menu,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive
        ? AppColors.textOnDark
        : AppColors.textOnDark.withValues(alpha: 0.72);

    return Tooltip(
      key: ValueKey<String>('menu-collapsed-${menu.id}'),
      message: menu.title.replaceAll('\n', ' '),
      excludeFromSemantics: true,
      child: Center(child: Icon(menu.icon, color: iconColor, size: 22)),
    );
  }
}

/// Puce d'état d'un sous-item de menu (pleine si actif, translucide sinon).
class SidebarSubMenuBullet extends StatelessWidget {
  final bool isActive;

  const SidebarSubMenuBullet({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.textOnDark
            : AppColors.textOnDark.withValues(alpha: 0.54),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Ligne complète d'un sous-item (puce + libellé) avec adaptation overflow.
class SidebarSubMenuItemRow extends StatelessWidget {
  final String title;
  final bool isActive;

  const SidebarSubMenuItemRow({
    super.key,
    required this.title,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final activeForeground = AppColors.textOnDark;
    final inactiveForeground = AppColors.textOnDark.withValues(alpha: 0.72);

    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Pendant l'animation de collapse la largeur peut devenir très petite:
          // masquer le marqueur fixe pour éviter l'overflow.
          final canShowBullet = constraints.maxWidth >= 24;

          return Row(
            children: [
              if (canShowBullet) ...[
                SidebarSubMenuBullet(isActive: isActive),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? activeForeground : inactiveForeground,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Container du sous-item avec fond conditionnel selon l'état actif.
class SidebarSubMenuItemContainer extends StatelessWidget {
  final domain.SubMenuItem subMenu;

  const SidebarSubMenuItemContainer({super.key, required this.subMenu});

  @override
  Widget build(BuildContext context) {
    final transparent = AppColors.surface.withValues(alpha: 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      padding: const EdgeInsets.symmetric(
        horizontal: HomeNavigationUiTokens.sidebarSubMenuItemHorizontalPadding,
        vertical: HomeNavigationUiTokens.sidebarSubMenuItemVerticalPadding,
      ),
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        color: subMenu.isActive
            ? AppColors.bleuArdoise.withValues(alpha: 0.2)
            : transparent,
        borderRadius: AppRadius.brSm,
      ),
      child: SidebarSubMenuItemRow(
        title: subMenu.title,
        isActive: subMenu.isActive,
      ),
    );
  }
}
