import 'package:flutter/material.dart';

/// Cible de navigation interne à la coquille (menu › sous-écran).
///
/// La page d'accueil ne route pas via GoRouter : elle pilote la même
/// [NavigationBloc] que la sidebar en émettant `SubMenuItemSelected`. Cette
/// classe transporte les trois informations nécessaires : le menu parent, le
/// sous-menu cible et le titre à afficher (fil d'Ariane / barre supérieure).
@immutable
class AccueilNavTarget {
  final String menuId;
  final String subMenuId;
  final String title;

  const AccueilNavTarget({
    required this.menuId,
    required this.subMenuId,
    required this.title,
  });
}

/// Puce de lien rapide affichée dans le pied d'une carte module (spec §04).
@immutable
class AccueilQuickLink {
  final String label;
  final AccueilNavTarget target;

  const AccueilQuickLink({required this.label, required this.target});
}

/// Carte de présentation d'un module sur la page d'accueil (spec §03).
///
/// Décrit l'application : un médaillon coloré, un titre, une phrase de
/// description et des puces de liens rapides. La carte entière mène au tableau
/// de bord du module ([dashboardTarget]) ; chaque puce a sa propre cible.
@immutable
class AccueilModule {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final Color softBackground;
  final AccueilNavTarget dashboardTarget;
  final List<AccueilQuickLink> quickLinks;

  const AccueilModule({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.softBackground,
    required this.dashboardTarget,
    required this.quickLinks,
  });
}
