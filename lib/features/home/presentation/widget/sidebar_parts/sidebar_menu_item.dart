import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/home/domain/entity/menu_item.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/home_navigation_ui_tokens.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar_parts/sidebar_menu_item_parts.dart';

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
            toggled: widget.menu.subMenus.isNotEmpty
                ? widget.isMenuOpened
                : false,
            child: InkWell(
              borderRadius: AppRadius.brMd,
              hoverColor: AppColors.textOnDark.withValues(alpha: 0.06),
              splashColor: AppColors.textOnDark.withValues(alpha: 0.1),
              highlightColor: AppColors.textOnDark.withValues(alpha: 0.08),
              onTap: () {
                context.read<NavigationBloc>().add(
                  MenuItemSelected(widget.menu.id),
                );
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
              child: InkWell(
                borderRadius: AppRadius.brSm,
                hoverColor: AppColors.textOnDark.withValues(alpha: 0.06),
                splashColor: AppColors.textOnDark.withValues(alpha: 0.1),
                highlightColor: AppColors.textOnDark.withValues(alpha: 0.08),
                onTap: () {
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
                },
                child: SidebarSubMenuItemContainer(subMenu: subMenu),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
