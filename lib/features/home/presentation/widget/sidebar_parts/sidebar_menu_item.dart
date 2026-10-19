import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/web/new_tab.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/home/domain/entity/menu_item.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/home_navigation_ui_tokens.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar_parts/sidebar_menu_item_parts.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar_parts/sidebar_rail_flyout.dart';

class SidebarMenuItem extends StatefulWidget {
  final MenuItem menu;
  final bool isExpanded;
  final bool isMenuOpened;
  final bool closeDrawerOnSubMenuSelection;

  const SidebarMenuItem({
    super.key,
    required this.menu,
    required this.isExpanded,
    required this.isMenuOpened,
    this.closeDrawerOnSubMenuSelection = false,
  });

  @override
  State<SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<SidebarMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(),
        AnimatedSwitcher(
          duration: AppMotion.medium,
          switchInCurve: AppMotion.gentleOut,
          switchOutCurve: AppMotion.inCurve,
          child:
              widget.isExpanded &&
                  widget.isMenuOpened &&
                  widget.menu.subMenus.isNotEmpty
              ? KeyedSubtree(
                  key: ValueKey<String>('submenu-open-${widget.menu.id}'),
                  child: _buildSubMenus(),
                )
              : const SizedBox.shrink(key: ValueKey<String>('submenu-closed')),
        ),
      ],
    );
  }

  Widget _buildMenuItem() {
    if (widget.isExpanded || widget.menu.isLeaf) return _menuTile();
    return SidebarRailFlyout(
      menu: widget.menu,
      onSelected: _selectSubMenu,
      builder: (context, toggle) => _menuTile(toggleFlyout: toggle),
    );
  }

  /// Le sous-menu choisi, dans la barre ou dans le menu flottant du rail.
  /// Ctrl+clic (web) l'ouvre dans un nouvel onglet.
  void _selectSubMenu(SubMenuItem subMenu) {
    if (NewTab.requestedByModifier) {
      NewTab.open(AppRoutesNames.homeSubMenuPath(subMenu.id));
      return;
    }
    context.read<NavigationBloc>().add(
      SubMenuItemSelected(
        menuId: widget.menu.id,
        subMenuId: subMenu.id,
        title: subMenu.title,
      ),
    );
    if (widget.closeDrawerOnSubMenuSelection) {
      Navigator.of(context).maybePop();
    }
  }

  Widget _menuTile({VoidCallback? toggleFlyout}) {
    final isActive = widget.menu.isActive;
    final transparent = AppColors.surface.withValues(alpha: 0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isExpanded
            ? HomeNavigationUiTokens.sidebarMenuExpandedHorizontalMargin
            : HomeNavigationUiTokens.sidebarMenuCollapsedHorizontalMargin,
        vertical: HomeNavigationUiTokens.sidebarMenuVerticalMargin,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: transparent,
          borderRadius: AppRadius.brMd,
          child: Semantics(
            button: true,
            label: widget.menu.title,
            selected: isActive,
            // Parent = accordéon (état développé/réduit) ; feuille = null pour
            // n'exposer que bouton + sélectionné (pas de sémantique
            // d'interrupteur « désactivé » sur un simple lien, cf. spec §09).
            // En rail, l'accordéon n'existe pas : le menu flottant se dit
            // de lui-même.
            expanded: widget.menu.subMenus.isNotEmpty && widget.isExpanded
                ? widget.isMenuOpened
                : null,
            child: InkWell(
              focusColor: AppColors.stateFocusOnDark,
              borderRadius: AppRadius.brMd,
              hoverColor: AppColors.textOnDark.withValues(alpha: 0.06),
              splashColor: AppColors.textOnDark.withValues(alpha: 0.1),
              highlightColor: AppColors.textOnDark.withValues(alpha: 0.08),
              onTap: () {
                // Rail : les sous-menus s'ouvrent en menu flottant, la barre
                // reste repliée.
                if (toggleFlyout != null) {
                  toggleFlyout();
                  return;
                }
                final bloc = context.read<NavigationBloc>();
                // Item feuille (ex. Accueil) : on sélectionne directement
                // l'écran (pas d'accordéon) et, en mode tiroir, on le ferme.
                if (widget.menu.isLeaf) {
                  bloc.add(
                    SubMenuItemSelected(
                      menuId: widget.menu.id,
                      subMenuId: widget.menu.id,
                      title: widget.menu.title,
                    ),
                  );
                  if (widget.closeDrawerOnSubMenuSelection) {
                    Navigator.of(context).maybePop();
                  }
                } else {
                  bloc.add(MenuItemSelected(widget.menu.id));
                }
              },
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.outCurve,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isExpanded
                      ? HomeNavigationUiTokens
                            .sidebarMenuExpandedHorizontalPadding
                      : HomeNavigationUiTokens
                            .sidebarMenuCollapsedHorizontalPadding,
                  vertical: HomeNavigationUiTokens.sidebarMenuVerticalPadding,
                ),
                constraints: const BoxConstraints(
                  minHeight: AppDimensions.minTouchTarget,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.bleuArdoise.withValues(alpha: 0.3)
                      : _isHovered
                      ? AppColors.textOnDark.withValues(alpha: 0.09)
                      : transparent,
                  borderRadius: AppRadius.brMd,
                  border: isActive
                      ? Border.all(
                          color: AppColors.bleuArdoise.withValues(alpha: 0.6),
                        )
                      : null,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canShowExpandedContent =
                        widget.isExpanded && constraints.maxWidth >= 110;

                    return AnimatedSwitcher(
                      duration: AppMotion.fast,
                      switchInCurve: AppMotion.outCurve,
                      switchOutCurve: AppMotion.inCurve,
                      child: canShowExpandedContent
                          ? SidebarMenuItemExpandedRow(
                              menu: widget.menu,
                              isActive: isActive,
                              isMenuOpened: widget.isMenuOpened,
                              canShowText: canShowExpandedContent,
                            )
                          : SidebarMenuItemCollapsedIcon(
                              menu: widget.menu,
                              isActive: isActive,
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubMenus() {
    final transparent = AppColors.surface.withValues(alpha: 0);

    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.gentleOut,
      margin: const EdgeInsets.fromLTRB(
        HomeNavigationUiTokens.sidebarSubMenuLeftMargin,
        HomeNavigationUiTokens.sidebarSubMenuTopMargin,
        HomeNavigationUiTokens.sidebarSubMenuRightMargin,
        HomeNavigationUiTokens.sidebarSubMenuBottomMargin,
      ),
      padding: const EdgeInsets.all(
        HomeNavigationUiTokens.sidebarSubMenuPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.textOnDark.withValues(alpha: 0.05),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        children: widget.menu.subMenus.map((subMenu) {
          return Material(
            color: transparent,
            child: Semantics(
              button: true,
              label: subMenu.title,
              selected: subMenu.isActive,
              // Web : Ctrl+clic ou clic molette ouvrent l'écran dans un nouvel
              // onglet — il a son adresse depuis que la coquille en donne une
              // à chaque sous-menu.
              child: MiddleClickOpensTab(
                path: AppRoutesNames.homeSubMenuPath(subMenu.id),
                child: InkWell(
                  focusColor: AppColors.stateFocusOnDark,
                  borderRadius: AppRadius.brSm,
                  hoverColor: AppColors.textOnDark.withValues(alpha: 0.06),
                  splashColor: AppColors.textOnDark.withValues(alpha: 0.1),
                  highlightColor: AppColors.textOnDark.withValues(alpha: 0.08),
                  onTap: () => _selectSubMenu(subMenu),
                  child: SidebarSubMenuItemContainer(subMenu: subMenu),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
