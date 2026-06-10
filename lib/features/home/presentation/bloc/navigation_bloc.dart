import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/domain/entity/menu_item.dart';
import 'package:school_app_flutter/features/home/domain/factories/menu_factory.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc(AppLocalizations l10n) : super(NavigationState.initial(l10n)) {
    on<MenuItemSelected>(_onMenuItemSelected);
    on<SubMenuItemSelected>(_onSubMenuItemSelected);
    on<SidebarToggled>(_onSidebarToggled);
  }

  void _onMenuItemSelected(
    MenuItemSelected event,
    Emitter<NavigationState> emit,
  ) {
    final isSameOpenedMenu = state.openedMenuId == event.menuId;
    final nextOpenedMenuId = isSameOpenedMenu ? null : event.menuId;
    final updatedMenus = state.menuItems.map((menu) {
      final shouldBeActive = nextOpenedMenuId == menu.id;
      final updatedSubMenus = menu.subMenus.map((subMenu) {
        return subMenu.copyWith(
          isActive: shouldBeActive && subMenu.id == state.selectedSubMenuId,
        );
      }).toList();

      if (menu.id == event.menuId) {
        return menu.copyWith(
          isActive: shouldBeActive,
          subMenus: updatedSubMenus,
        );
      }
      return menu.copyWith(isActive: false, subMenus: updatedSubMenus);
    }).toList();

    emit(
      state.copyWith(
        menuItems: updatedMenus,
        selectedMenuId: nextOpenedMenuId,
        // Déployer/replier un accordéon est une action de divulgation, pas de
        // navigation : on conserve l'écran affiché (selectedSubMenuId inchangé,
        // donc non passé au copyWith). Sans cela, refermer un module depuis
        // l'Accueil — ou depuis n'importe quelle page — retombait sur le
        // placeholder « page en construction » (cul-de-sac, cf. revue spec §00).
        openedMenuId: nextOpenedMenuId,
        isSidebarExpanded: state.isSidebarExpanded ? null : true,
      ),
    );
  }

  void _onSubMenuItemSelected(
    SubMenuItemSelected event,
    Emitter<NavigationState> emit,
  ) {
    final updatedMenus = state.menuItems.map((menu) {
      final updatedSubMenus = menu.subMenus.map((subMenu) {
        return subMenu.copyWith(isActive: subMenu.id == event.subMenuId);
      }).toList();

      return menu.copyWith(
        subMenus: updatedSubMenus,
        isActive: menu.id == event.menuId,
      );
    }).toList();

    emit(
      state.copyWith(
        menuItems: updatedMenus,
        selectedMenuId: event.menuId,
        selectedSubMenuId: event.subMenuId,
        openedMenuId: event.menuId,
        currentTitle: event.title,
      ),
    );
  }

  void _onSidebarToggled(SidebarToggled event, Emitter<NavigationState> emit) {
    emit(state.copyWith(isSidebarExpanded: !state.isSidebarExpanded));
  }
}
