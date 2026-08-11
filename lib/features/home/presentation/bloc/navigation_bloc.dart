import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/domain/entity/menu_item.dart';
import 'package:school_app_flutter/features/home/domain/factories/menu_factory.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc(AppLocalizations l10n, {required List<String>? permissions})
    : super(NavigationState.initial(l10n, permissions: permissions)) {
    on<MenuItemSelected>(_onMenuItemSelected);
    on<SubMenuItemSelected>(_onSubMenuItemSelected);
    on<SidebarToggled>(_onSidebarToggled);
    on<NavigationPermissionsChanged>(_onPermissionsChanged);
  }

  /// Reconstruit l'arborescence sur le nouvel ensemble de droits, en préservant
  /// l'écran affiché **s'il reste accessible** — sinon on retombe sur l'accueil
  /// plutôt que de laisser l'utilisateur sur une page qu'il n'a plus le droit
  /// d'ouvrir. Le titre suit, sans quoi la barre supérieure annoncerait un
  /// écran qui n'est plus là.
  void _onPermissionsChanged(
    NavigationPermissionsChanged event,
    Emitter<NavigationState> emit,
  ) {
    final menus = MenuFactory.createMenuItems(
      event.l10n,
      permissions: event.permissions,
    );
    final selected = state.selectedSubMenuId;
    final stillVisible =
        selected == MenuConstants.accueilId ||
        menus.any((m) => m.subMenus.any((s) => s.id == selected));

    if (stillVisible) {
      emit(
        state.copyWith(
          menuItems: menus
              .map(
                (menu) => menu.copyWith(
                  isActive: menu.id == state.selectedMenuId,
                  subMenus: menu.subMenus
                      .map((sub) => sub.copyWith(isActive: sub.id == selected))
                      .toList(),
                ),
              )
              .toList(),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        menuItems: menus
            .map(
              (menu) =>
                  menu.copyWith(isActive: menu.id == MenuConstants.accueilId),
            )
            .toList(),
        selectedMenuId: MenuConstants.accueilId,
        selectedSubMenuId: MenuConstants.accueilId,
        openedMenuId: MenuConstants.accueilId,
        currentTitle: event.l10n.home,
      ),
    );
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
    // La coquille ne route pas par GoRouter pour ses écrans : elle bascule sur
    // cet événement, que deux widgets émettent avec un identifiant EN DUR pour
    // sauter d'un module à l'autre (tableau de bord présence → feuille d'appel,
    // état vide de l'appel → composition des classes). Ces émetteurs ne passent
    // par aucune liste filtrée : sans cette garde, la politique ne s'applique
    // qu'aux chemins qui veulent bien la traverser.
    //
    // On teste l'appartenance à l'arborescence courante, déjà filtrée par les
    // permissions — `menu.id` compris, car l'item feuille Accueil émet un
    // `subMenuId` égal à son propre identifiant.
    final atteignable = state.menuItems.any(
      (menu) =>
          menu.id == event.subMenuId ||
          menu.subMenus.any((sub) => sub.id == event.subMenuId),
    );
    if (!atteignable) return;

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
