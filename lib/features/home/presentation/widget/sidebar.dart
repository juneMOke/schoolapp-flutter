import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar_parts/sidebar_footer.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar_parts/sidebar_header.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar_parts/sidebar_menu_item.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class Sidebar extends StatelessWidget {
  final bool closeDrawerOnSubMenuSelection;

  /// Force l'affichage déployé (280), même si l'état bureau est replié.
  /// Utilisé en mode tiroir : la sidebar overlay est toujours déployée.
  final bool forceExpanded;

  const Sidebar({
    super.key,
    this.closeDrawerOnSubMenuSelection = false,
    this.forceExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<NavigationBloc, NavigationState>(
      buildWhen: (previous, current) =>
          previous.isSidebarExpanded != current.isSidebarExpanded ||
          previous.menuItems != current.menuItems,
      builder: (context, state) {
        // En mode tiroir (forceExpanded), la sidebar reste toujours déployée,
        // même si l'état bureau était replié.
        final isExpanded = forceExpanded || state.isSidebarExpanded;
        return Semantics(
          container: true,
          label: l10n.homeSidebarNavigationLabel,
          explicitChildNodes: true,
          child: AnimatedContainer(
            duration: AppMotion.layout,
            curve: AppMotion.outCurve,
            width: isExpanded
                ? AppTheme.sidebarWidth
                : AppTheme.sidebarCollapsedWidth,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                border: Border(
                  right: BorderSide(color: AppColors.borderStrong),
                ),
              ),
              child: SafeArea(
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: Column(
                    children: [
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(1),
                        child: SidebarHeader(isExpanded: isExpanded),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS + 2),
                      Expanded(
                        child: FocusTraversalOrder(
                          order: const NumericFocusOrder(2),
                          child: _buildMenuList(context, state, isExpanded),
                        ),
                      ),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(3),
                        child: SidebarFooter(isExpanded: isExpanded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuList(
    BuildContext context,
    NavigationState state,
    bool isExpanded,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.menuItems.length,
      semanticChildCount: state.menuItems.length,
      itemBuilder: (context, index) {
        final menu = state.menuItems[index];
        return IndexedSemantics(
          index: index,
          child: SidebarMenuItem(
            menu: menu,
            isExpanded: isExpanded,
            isMenuOpened: state.openedMenuId == menu.id,
            closeDrawerOnSubMenuSelection: closeDrawerOnSubMenuSelection,
          ),
        );
      },
    );
  }
}
