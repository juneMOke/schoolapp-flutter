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

/// Les droits de la session ont changé (refresh porteur d'un nouvel ensemble,
/// ADR-014 §5) : l'arborescence est reconstruite sur le nouveau périmètre.
///
/// Sans cet événement, le menu resterait celui du login — un droit retiré
/// continuerait d'offrir sa porte jusqu'au prochain démarrage.
class NavigationPermissionsChanged extends NavigationEvent {
  final AppLocalizations l10n;
  final List<String>? permissions;

  const NavigationPermissionsChanged({
    required this.l10n,
    required this.permissions,
  });

  @override
  List<Object?> get props => [l10n, permissions];
}
