import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar_parts/sidebar_footer.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar_parts/sidebar_header.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar_parts/sidebar_menu_item.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return AnimatedContainer(
          duration: AppMotion.layout,
          curve: AppMotion.outCurve,
          width: state.isSidebarExpanded
              ? AppTheme.sidebarWidth
              : AppTheme.sidebarCollapsedWidth,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.sidebarGradientTop,
                  AppTheme.sidebarColor,
                  AppTheme.sidebarGradientBottom,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 14,
                  offset: Offset(3, 0),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  SidebarHeader(isExpanded: state.isSidebarExpanded),
                  const SizedBox(height: 6),
                  Expanded(child: _buildMenuList(context, state)),
                  SidebarFooter(isExpanded: state.isSidebarExpanded),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuList(BuildContext context, NavigationState state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.menuItems.length,
      itemBuilder: (context, index) {
        final menu = state.menuItems[index];
        return SidebarMenuItem(menu: menu, isExpanded: state.isSidebarExpanded);
      },
    );
  }
}
