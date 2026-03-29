part of 'navigation_bloc.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

class NavigationInitialized extends NavigationEvent {
  final AppLocalizations l10n;

  const NavigationInitialized(this.l10n);

  @override
  List<Object?> get props => [l10n];
}

class MenuItemSelected extends NavigationEvent {
  final String menuId;

  const MenuItemSelected(this.menuId);

  @override
  List<Object?> get props => [menuId];
}

class SubMenuItemSelected extends NavigationEvent {
  final String menuId;
  final String subMenuId;
  final String title;

  const SubMenuItemSelected({
    required this.menuId,
    required this.subMenuId,
    required this.title,
  });

  @override
  List<Object?> get props => [menuId, subMenuId, title];
}

class SidebarToggled extends NavigationEvent {
  const SidebarToggled();
}