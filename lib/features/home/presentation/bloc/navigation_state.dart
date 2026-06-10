part of 'navigation_bloc.dart';

const Object _undefined = Object();

class NavigationState extends Equatable {
  final List<MenuItem> menuItems;
  final String? selectedMenuId;
  final String? selectedSubMenuId;
  final String? openedMenuId;
  final bool isSidebarExpanded;
  final String currentTitle;

  const NavigationState({
    required this.menuItems,
    this.selectedMenuId,
    this.selectedSubMenuId,
    this.openedMenuId,
    required this.isSidebarExpanded,
    required this.currentTitle,
  });

  factory NavigationState.initial(AppLocalizations l10n) {
    // Atterrissage post-connexion sur la page d'accueil (spec Accueil §00/§09) :
    // l'entrée feuille « Accueil » est l'item actif, le contenu affiché est la
    // page d'accueil. Aucun menu module n'est déployé.
    final initialMenuItems = MenuFactory.createMenuItems(l10n).map((menu) {
      return menu.copyWith(isActive: menu.id == MenuConstants.accueilId);
    }).toList();

    return NavigationState(
      menuItems: initialMenuItems,
      selectedMenuId: MenuConstants.accueilId,
      selectedSubMenuId: MenuConstants.accueilId,
      openedMenuId: MenuConstants.accueilId,
      isSidebarExpanded: true,
      currentTitle: l10n.home,
    );
  }

  NavigationState copyWith({
    List<MenuItem>? menuItems,
    Object? selectedMenuId = _undefined,
    Object? selectedSubMenuId = _undefined,
    Object? openedMenuId = _undefined,
    bool? isSidebarExpanded,
    String? currentTitle,
  }) {
    return NavigationState(
      menuItems: menuItems ?? this.menuItems,
      selectedMenuId: identical(selectedMenuId, _undefined)
          ? this.selectedMenuId
          : selectedMenuId as String?,
      selectedSubMenuId: identical(selectedSubMenuId, _undefined)
          ? this.selectedSubMenuId
          : selectedSubMenuId as String?,
      openedMenuId: identical(openedMenuId, _undefined)
          ? this.openedMenuId
          : openedMenuId as String?,
      isSidebarExpanded: isSidebarExpanded ?? this.isSidebarExpanded,
      currentTitle: currentTitle ?? this.currentTitle,
    );
  }

  @override
  List<Object?> get props => [
    menuItems,
    selectedMenuId,
    selectedSubMenuId,
    openedMenuId,
    isSidebarExpanded,
    currentTitle,
  ];
}
