import 'package:flutter/widgets.dart';

/// Forme du panneau d'options.
///
/// [adaptive] est le mode par défaut : le panneau suit le même arbitrage
/// responsive que le reste de l'application — ancré sous le champ quand
/// l'écran est assez large pour que le formulaire reste visible autour,
/// feuille modale sinon, où un popover de 300 dp serait à la fois trop
/// étroit pour lire et trop bas pour être atteint au pouce.
enum EteeloSelectPanelMode { adaptive, popover, sheet }

/// Gabarit du champ fermé.
///
/// [compact] sert aux sélecteurs posés **dans** une ligne déjà dense (ligne de
/// panier, barre de tri d'un tableau) : ils n'ont pas de libellé au-dessus et
/// ne doivent pas imposer la hauteur de touche pleine à la rangée qui les
/// contient.
enum EteeloSelectDensity { standard, compact }

/// Ton du texte de substitution quand rien n'est choisi.
///
/// [alert] est réservé au champ **vide qui bloque** une suite (le niveau d'une
/// ligne de panier walk-in, sans lequel aucun prix ne se résout) : il attire
/// l'œil sans occuper une ligne de plus sous le champ, là où un message
/// d'erreur déplacerait toute la rangée qui l'entoure.
enum EteeloSelectPlaceholderTone { muted, alert }

@immutable
class EteeloSelectItem<T> {
  final T value;
  final String label;
  final bool enabled;

  /// Ligne secondaire sous le libellé (effectif d'une classe, code d'un frais…).
  /// Elle n'est jamais le libellé tronqué : ce qui identifie l'option reste en
  /// première ligne.
  final String? subtitle;

  /// Pastille de tête. Réservée aux listes où l'icône **distingue** (mode de
  /// paiement, type de pièce) ; une icône identique sur chaque ligne n'ajoute
  /// rien et vole la largeur du libellé.
  final IconData? icon;

  /// Termes de recherche supplémentaires, invisibles à l'écran (code officiel,
  /// ancienne dénomination, abréviation d'usage au guichet).
  final String? searchTerms;

  const EteeloSelectItem({
    required this.value,
    required this.label,
    this.enabled = true,
    this.subtitle,
    this.icon,
    this.searchTerms,
  });
}
