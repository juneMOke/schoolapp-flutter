import 'package:flutter/material.dart';

/// Habillage **teinté** d'une table (spec Première inscription §04).
///
/// `null` sur [DataTableViewConfig.tone] — le défaut — rend la table exactement
/// comme avant : surface blanche, en-tête blanc, aucune zébrure. C'est
/// l'habillage de toutes les tables existantes de l'application, et il ne doit
/// pas bouger d'un pixel.
///
/// ## Pourquoi les couleurs arrivent déjà calculées
///
/// Le socle ne connaît pas les formules de dérivation d'un écran : elles vivent
/// dans le module qui les décide — `EnrollmentListingTones` pour les écrans de
/// liste d'inscription. Un composant de `core` ne peut pas importer un fichier
/// de `features`, et il n'a pas à savoir qu'un en-tête de table s'obtient en
/// assombrissant un ton de 20 % vers le bleu profond.
///
/// L'appelant compose donc sa teinte et la passe ; un autre écran pourra
/// adopter la variante avec la sienne, sans que ce fichier change.
///
/// ## Ce qu'une teinte ne fait pas
///
/// Elle ne colore **jamais le fond d'une ligne selon son statut**. Une liste
/// bicolore n'a plus de zébrure lisible, et le statut disparaît à l'impression
/// (§12). Le statut se porte par une pastille dans la cellule, ou par un filet
/// vertical en vue grille — jamais par la ligne elle-même.
@immutable
class DataTableTone {
  /// Bandeau plein d'en-tête — assez sombre pour porter une encre crème.
  final Color header;

  /// Encre des libellés de colonne.
  final Color headerInk;

  /// Encre de la colonne triée. Le tri se lit à cette nuance **et à la
  /// graisse**, jamais à une couleur d'accent qui entrerait en concurrence
  /// avec les couleurs de donnée des cellules.
  final Color headerInkSorted;

  /// Fond des lignes paires.
  ///
  /// L'écart avec les lignes impaires est volontairement infime : une zébrure
  /// **guide l'œil le long d'une ligne, elle ne dit rien**. Toute valeur qui la
  /// rendrait franchement visible ferait d'elle une information — et il n'y en
  /// a aucune à y mettre.
  final Color zebra;

  /// Bord du cadre de la table.
  final Color border;

  const DataTableTone({
    required this.header,
    required this.headerInk,
    required this.headerInkSorted,
    required this.zebra,
    required this.border,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataTableTone &&
          runtimeType == other.runtimeType &&
          header == other.header &&
          headerInk == other.headerInk &&
          headerInkSorted == other.headerInkSorted &&
          zebra == other.zebra &&
          border == other.border;

  @override
  int get hashCode =>
      Object.hash(header, headerInk, headerInkSorted, zebra, border);
}
