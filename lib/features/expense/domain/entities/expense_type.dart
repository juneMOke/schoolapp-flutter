import 'package:equatable/equatable.dart';

/// Un type de dépense tel que l'école le nomme — lu du socle référentiel
/// (`expenseTypes`), **jamais** codé en dur dans le poste (A9).
///
/// La présentation est une donnée : libellés, icône, couleur et teinte douce
/// descendent avec le type, pour que la configuration V2 n'ait rien à
/// retoucher dans les vues.
class ExpenseType extends Equatable {
  final String id;

  /// Clé stable (`ELECTRICITE`…) : le libellé n'en est pas une, l'école le
  /// réécrira.
  final String code;
  final String label;
  final String shortLabel;

  /// Nom d'icône du jeu Eteelo (`power`, `sparkles`…).
  final String icon;

  /// `#RRGGBB`.
  final String colorHex;
  final String softColorHex;

  /// Devise que le formulaire propose pour ce poste — un défaut, jamais une
  /// contrainte.
  final String defaultCurrency;
  final int sortOrder;

  /// `false` : ne se propose plus à la saisie, mais nomme encore ses
  /// dépenses.
  final bool active;

  const ExpenseType({
    required this.id,
    required this.code,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.colorHex,
    required this.softColorHex,
    required this.defaultCurrency,
    required this.sortOrder,
    required this.active,
  });

  @override
  List<Object?> get props => [
    id,
    code,
    label,
    shortLabel,
    icon,
    colorHex,
    softColorHex,
    defaultCurrency,
    sortOrder,
    active,
  ];
}
