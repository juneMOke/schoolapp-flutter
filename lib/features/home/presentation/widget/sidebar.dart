import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/home/domain/entity/menu_item.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';



class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: state.isSidebarExpanded
              ? AppTheme.sidebarWidth
              : AppTheme.sidebarCollapsedWidth,
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.sidebarColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(context, state.isSidebarExpanded),
                Expanded(child: _buildMenuList(context, state)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isExpanded) {
    return Container(
      height: AppTheme.topBarHeight,
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? AppTheme.defaultPadding : 8.0,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isExpanded
            ? _buildExpandedHeader(context)
            : _buildCollapsedHeader(context),
      ),
    );
  }

  Widget _buildExpandedHeader(BuildContext context) {
    return Row(
      key: const ValueKey('expanded'),
      children: [
        IconButton(
          onPressed: () => context.read<NavigationBloc>().add(const SidebarToggled()),
          icon: const Icon(Icons.menu, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.school, color: Colors.white, size: 32),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'ETEELO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedHeader(BuildContext context) {
    return Center(
      key: const ValueKey('collapsed'),
      child: IconButton(
        onPressed: () => context.read<NavigationBloc>().add(const SidebarToggled()),
        icon: const Icon(Icons.menu, color: Colors.white),
      ),
    );
  }

  Widget _buildMenuList(BuildContext context, NavigationState state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.defaultPadding),
      itemCount: state.menuItems.length,
      itemBuilder: (context, index) {
        final menu = state.menuItems[index];
        return _MenuItemWidget(menu: menu, isExpanded: state.isSidebarExpanded);
      },
    );
  }
}

class _MenuItemWidget extends StatefulWidget {
  final MenuItem menu;
  final bool isExpanded;

  const _MenuItemWidget({required this.menu, required this.isExpanded});

  @override
  State<_MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<_MenuItemWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(),
        if (widget.isExpanded && _isExpanded && widget.menu.subMenus.isNotEmpty)
          _buildSubMenus(),
      ],
    );
  }

  Widget _buildMenuItem() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (widget.menu.subMenus.isNotEmpty) {
            setState(() => _isExpanded = !_isExpanded);
          }
          context.read<NavigationBloc>().add(MenuItemSelected(widget.menu.id));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.defaultPadding,
            vertical: 12,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final canShowExpandedContent =
                  widget.isExpanded && constraints.maxWidth >= 110;

              return Row(
                children: [
                  Icon(
                    widget.menu.icon,
                    color: widget.menu.isActive
                        ? AppTheme.activeMenuColor
                        : Colors.white70,
                    size: 24,
                  ),
                  if (canShowExpandedContent) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.menu.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.menu.isActive
                              ? AppTheme.activeMenuColor
                              : Colors.white70,
                          fontSize: 16,
                          fontWeight: widget.menu.isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (widget.menu.subMenus.isNotEmpty)
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: widget.menu.isActive
                            ? AppTheme.activeMenuColor
                            : Colors.white70,
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSubMenus() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Column(
        children: widget.menu.subMenus.map((subMenu) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                context.read<NavigationBloc>().add(
                  SubMenuItemSelected(
                    menuId: widget.menu.id,
                    subMenuId: subMenu.id,
                    title: subMenu.title,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.only(
                  left: 56,
                  right: AppTheme.defaultPadding,
                  top: 8,
                  bottom: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: subMenu.isActive
                            ? AppTheme.activeMenuColor
                            : Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        subMenu.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subMenu.isActive
                              ? AppTheme.activeMenuColor
                              : Colors.white70,
                          fontSize: 14,
                          fontWeight: subMenu.isActive
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
