part of 'navigation_bloc.dart';

class NavigationState extends Equatable {
  final List<MenuItem> menuItems;
  final String? selectedMenuId;
  final String? selectedSubMenuId;
  final bool isSidebarExpanded;
  final String currentTitle;

  const NavigationState({
    required this.menuItems,
    this.selectedMenuId,
    this.selectedSubMenuId,
    required this.isSidebarExpanded,
    required this.currentTitle,
  });

  factory NavigationState.initial(AppLocalizations l10n) {
    return NavigationState(
      menuItems: MenuFactory.createMenuItems(l10n),
      isSidebarExpanded: true,
      currentTitle: l10n.subMenuDashboard,
    );
  }

  NavigationState copyWith({
    List<MenuItem>? menuItems,
    String? selectedMenuId,
    String? selectedSubMenuId,
    bool? isSidebarExpanded,
    String? currentTitle,
  }) {
    return NavigationState(
      menuItems: menuItems ?? this.menuItems,
      selectedMenuId: selectedMenuId ?? this.selectedMenuId,
      selectedSubMenuId: selectedSubMenuId ?? this.selectedSubMenuId,
      isSidebarExpanded: isSidebarExpanded ?? this.isSidebarExpanded,
      currentTitle: currentTitle ?? this.currentTitle,
    );
  }

  @override
  List<Object?> get props => [
    menuItems,
    selectedMenuId,
    selectedSubMenuId,
    isSidebarExpanded,
    currentTitle,
  ];
}
