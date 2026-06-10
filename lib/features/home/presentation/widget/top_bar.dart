import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/home_navigation_ui_tokens.dart';
import 'package:school_app_flutter/features/home/presentation/widget/top_bar_parts/top_bar_actions.dart';
import 'package:school_app_flutter/features/home/presentation/widget/top_bar_parts/top_bar_leading_menu_button.dart';
import 'package:school_app_flutter/features/home/presentation/widget/top_bar_parts/top_bar_title.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isCompact;
  final VoidCallback? onMenuPressed;

  const TopBar({super.key, this.isCompact = false, this.onMenuPressed});

  @override
  Size get preferredSize => const Size.fromHeight(AppTheme.topBarHeight);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      buildWhen: (previous, current) =>
          previous.currentTitle != current.currentTitle ||
          previous.selectedSubMenuId != current.selectedSubMenuId ||
          previous.selectedMenuId != current.selectedMenuId,
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final isPreRegistrations =
            state.selectedSubMenuId == MenuConstants.preInscriptionsId;
        // Sur l'Accueil, l'eyebrow porte le nom de marque (spec Accueil §09).
        final selectedMenuTitle =
            state.selectedSubMenuId == MenuConstants.accueilId
            ? l10n.schoolApp
            : _resolveSelectedMenuTitle(state);

        return AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppTheme.sidebarColor,
          foregroundColor: AppColors.textOnDark,
          leading: isCompact
              ? Builder(
                  builder: (context) => TopBarLeadingMenuButton(
                    onPressed:
                        onMenuPressed ??
                        () => Scaffold.of(context).openDrawer(),
                  ),
                )
              : null,
          // Padding horizontal de la barre : 24 (bureau) / 16 (compact).
          // En compact, le hamburger (leading) porte la marge gauche 16 ; le
          // titre démarre juste après (titleSpacing 0 + marge droite 2 du
          // hamburger). À droite, TopBarActions porte le end-padding 24/16.
          leadingWidth: isCompact
              ? HomeNavigationUiTokens.topBarCompactHorizontalPadding +
                    HomeNavigationUiTokens.topBarActionSize +
                    HomeNavigationUiTokens.topBarLeadingMarginRight
              : null,
          titleSpacing: isCompact
              ? 0
              : HomeNavigationUiTokens.topBarDesktopHorizontalPadding,
          toolbarHeight: AppTheme.topBarHeight,
          flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
              ),
              border: Border(
                bottom: BorderSide(color: Color(0x1AFAFAF7), width: 1),
              ),
            ),
          ),
          title: TopBarTitle(
            moduleTitle: selectedMenuTitle,
            title: state.currentTitle,
            isPreRegistrations: isPreRegistrations,
            selectedSubMenuId: state.selectedSubMenuId,
            isCompact: isCompact,
          ),
          actions: [TopBarActions(isCompact: isCompact)],
        );
      },
    );
  }

  String? _resolveSelectedMenuTitle(NavigationState state) {
    for (final menu in state.menuItems) {
      if (menu.id == state.selectedMenuId) {
        return menu.title;
      }
    }
    return null;
  }
}
