import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/home/domain/entity/menu_item.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';

class SidebarMenuItem extends StatefulWidget {
  final MenuItem menu;
  final bool isExpanded;

  const SidebarMenuItem({
    super.key,
    required this.menu,
    required this.isExpanded,
  });

  @override
  State<SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<SidebarMenuItem> {
  bool _isExpanded = false;
  bool _isHovered = false;

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
    final isActive = widget.menu.isActive;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isExpanded ? 10 : 6,
        vertical: 3,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (widget.menu.subMenus.isNotEmpty) {
                setState(() => _isExpanded = !_isExpanded);
              }
              context.read<NavigationBloc>().add(MenuItemSelected(widget.menu.id));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(
                horizontal: widget.isExpanded ? 12 : 0,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryColor.withValues(alpha: 0.2)
                    : _isHovered
                        ? Colors.white.withValues(alpha: 0.09)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isActive
                    ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.45))
                    : null,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canShowExpandedContent =
                      widget.isExpanded && constraints.maxWidth >= 110;

                  return Row(
                    mainAxisAlignment: widget.isExpanded
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.menu.icon,
                        color: isActive ? Colors.white : Colors.white70,
                        size: 22,
                      ),
                      if (canShowExpandedContent) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.menu.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.white70,
                              fontSize: 14,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (widget.menu.subMenus.isNotEmpty)
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: isActive ? Colors.white : Colors.white70,
                            size: 18,
                          ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubMenus() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(left: 16, right: 10, bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: widget.menu.subMenus.map((subMenu) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
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
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: subMenu.isActive
                      ? AppTheme.primaryColor.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: subMenu.isActive ? Colors.white : Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        subMenu.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subMenu.isActive ? Colors.white : Colors.white70,
                          fontSize: 13,
                          fontWeight: subMenu.isActive ? FontWeight.w600 : FontWeight.w500,
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
