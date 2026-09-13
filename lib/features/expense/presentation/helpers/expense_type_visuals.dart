import 'package:flutter/material.dart';

/// Traduit la présentation d'un type de dépense — une **donnée** du socle —
/// en objets Flutter.
///
/// Le serveur nomme ses icônes dans le jeu Eteelo (noms Lucide : `power`,
/// `shield-check`…) et ses couleurs en `#RRGGBB`. Aucune couleur de type n'est
/// écrite dans une vue (spec §Fondations) : elles viennent toutes d'ici, à
/// partir de ce que l'école a reçu.
abstract final class ExpenseTypeVisuals {
  /// Icône de repli : un type neuf, nommé dans une icône que ce poste ne
  /// connaît pas encore, reste lisible.
  static const IconData fallbackIcon = Icons.receipt_long_outlined;

  static const Map<String, IconData> _icons = {
    'power': Icons.bolt_outlined,
    'arrow-right-left': Icons.swap_horiz_rounded,
    'book-marked': Icons.menu_book_outlined,
    'settings': Icons.build_outlined,
    'phone': Icons.phone_outlined,
    'shield-check': Icons.verified_user_outlined,
    'sparkles': Icons.auto_awesome_outlined,
    'shopping-bag': Icons.shopping_bag_outlined,
    'layers': Icons.layers_outlined,
    'home': Icons.home_outlined,
    'wallet': Icons.account_balance_wallet_outlined,
    'landmark': Icons.account_balance_outlined,
    'users': Icons.groups_outlined,
    'truck': Icons.local_shipping_outlined,
    'utensils': Icons.restaurant_outlined,
    'receipt': Icons.receipt_long_outlined,
  };

  static IconData icon(String name) =>
      _icons[name.trim().toLowerCase()] ?? fallbackIcon;

  /// `#RRGGBB` → couleur opaque ; `null` sur une valeur illisible, que
  /// l'appelant remplace par un jeton du thème.
  static Color? color(String hex) {
    final value = hex.trim();
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) return null;
    return Color(0xFF000000 | int.parse(value.substring(1), radix: 16));
  }
}
