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

/// Sous-module listé dans le pied d'une carte module (spec §03/§04).
///
/// [isDashboard] distingue la ligne « Tableau de bord » — mise en avant
/// (médaillon + fond doux + libellé gras) — des autres pages du module, qui
/// s'affichent en lignes légères à puce.
@immutable
class AccueilSubModule {
  final String label;
  final AccueilNavTarget target;
  final bool isDashboard;

  const AccueilSubModule({
    required this.label,
    required this.target,
    this.isDashboard = false,
  });
}

/// Carte de présentation d'un module sur la page d'accueil (spec §03).
///
/// Décrit l'application : un médaillon coloré, un titre, le nombre de pages,
/// une phrase de description et la liste de ses sous-modules. L'en-tête mène à
/// la page d'entrée du module ([entryTarget]) ; chaque ligne à son sous-écran.
@immutable
class AccueilModule {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final Color softBackground;
  final List<AccueilSubModule> subModules;

  const AccueilModule({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.softBackground,
    required this.subModules,
  }) : assert(subModules.length > 0, 'Un module a au moins une page');

  /// Page d'entrée du module (spec §03) : le tableau de bord s'il existe,
  /// sinon le premier sous-module. Ainsi Cours ouvre « Emploi du temps » et
  /// Résultats « Résultats par classe ».
  AccueilSubModule get entry => subModules.firstWhere(
    (sub) => sub.isDashboard,
    orElse: () => subModules.first,
  );

  /// Nombre de pages annoncé sous le titre de la carte.
  int get pageCount => subModules.length;

  /// Utilisé par la fabrique pour restreindre la carte aux sous-modules
  /// autorisés (ADR-014). [pageCount] et [entry] suivent : une carte filtrée
  /// annonce le nombre de pages réellement offertes et s'ouvre sur la première
  /// que l'utilisateur peut atteindre.
  AccueilModule copyWith({List<AccueilSubModule>? subModules}) => AccueilModule(
    id: id,
    title: title,
    description: description,
    icon: icon,
    accent: accent,
    softBackground: softBackground,
    subModules: subModules ?? this.subModules,
  );
}
