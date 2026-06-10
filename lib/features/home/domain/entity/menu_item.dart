import 'package:flutter/material.dart';

class MenuItem {
  final String id;
  final String title;
  final IconData icon;
  final List<SubMenuItem> subMenus;
  final bool isActive;

  const MenuItem({
    required this.id,
    required this.title,
    required this.icon,
    this.subMenus = const [],
    this.isActive = false,
  });

  /// Item feuille : aucune sous-entrée. Le clic sélectionne directement l'écran
  /// (pas d'accordéon, pas de chevron) — cf. entrée « Accueil » (spec §09).
  bool get isLeaf => subMenus.isEmpty;

  MenuItem copyWith({
    String? id,
    String? title,
    IconData? icon,
    List<SubMenuItem>? subMenus,
    bool? isActive,
  }) {
    return MenuItem(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      subMenus: subMenus ?? this.subMenus,
      isActive: isActive ?? this.isActive,
    );
  }
}

class SubMenuItem {
  final String id;
  final String title;
  final String route;
  final bool isActive;

  const SubMenuItem({
    required this.id,
    required this.title,
    required this.route,
    this.isActive = false,
  });

  SubMenuItem copyWith({
    String? id,
    String? title,
    String? route,
    bool? isActive,
  }) {
    return SubMenuItem(
      id: id ?? this.id,
      title: title ?? this.title,
      route: route ?? this.route,
      isActive: isActive ?? this.isActive,
    );
  }
}
