import 'package:flutter/material.dart';

/// Données génériques pour une carte KPI.
class EteeloKpiCardData {
  final String label;

  /// Valeur entière (compteurs). Ignorée si [valueText] est fourni.
  final int? value;

  /// Valeur déjà formatée (montant monétaire, pourcentage…). Prioritaire sur
  /// [value] — permet de réutiliser la carte pour des indicateurs non entiers
  /// (ex. KPIs financiers en devise).
  final String? valueText;

  /// Plusieurs valeurs à **empiler**, quand l'indicateur n'en a pas qu'une.
  ///
  /// Le cas qui l'a fait naître : un montant par devise. 425,00 $ et 90 000 FC
  /// ne se somment pas — leur total n'existe pas — donc ils s'écrivent l'un
  /// sous l'autre, chacun entier et lisible, plutôt que rétrécis sur une seule
  /// ligne par le `FittedBox`.
  ///
  /// Prioritaire sur [valueText] et [value]. Une liste d'un seul élément rend
  /// exactement comme [valueText] : c'est ce qui garde le cas mono-devise
  /// identique à ce qu'il était.
  final List<String>? valueLines;

  final int? percent;
  final Color accent;
  final Color accentSoft;
  final IconData icon;

  /// Fond plein d'un pavé **sombre**, ou `null` — le défaut — pour la carte
  /// claire historique.
  ///
  /// Un seul champ plutôt qu'un booléen doublé d'une couleur : il est ainsi
  /// impossible de déclarer une carte pleine sans dire de quelle couleur, ou
  /// une couleur de fond qui ne serait jamais peinte.
  ///
  /// La couleur n'est pas calculée ici : le socle ne connaît pas la formule
  /// d'assombrissement d'un écran donné. L'appelant la dérive — pour le
  /// tableau de bord des inscriptions, `EnrollmentDashboardTones.pave()` — et
  /// la passe. Un autre écran pourra adopter la variante avec la sienne.
  final Color? filledBackground;

  /// Encre des valeurs **après la première**, sur un pavé plein.
  ///
  /// `null` — le défaut — les peint comme la première, ce qui laisse le rendu
  /// historique inchangé à l'octet pour toutes les cartes existantes.
  ///
  /// N'a d'effet qu'avec [filledBackground] et [valueLines] : c'est le cas de
  /// la carte bi-devise, où la seconde ligne est un **second montant** et non
  /// un commentaire du premier. La nuance le dit sans mot.
  ///
  /// Comme [filledBackground], la couleur vient de l'appelant : le socle ne
  /// connaît pas la teinte du pavé, donc pas la nuance qui s'y lit. Le
  /// tableau de bord la dérive par `DashboardTones.encreSecondeValeur()`.
  final Color? filledSecondaryInk;

  /// Sous-ligne optionnelle affichee sous la valeur (ex. « 510 eleve-jours »).
  /// Rendue en caption discrete ; les cartes qui en ont sont legerement plus
  /// hautes ([AppDimensions.kpiCardHeightWithSubline]) — celles qui n'en ont
  /// pas conservent le rendu et la hauteur historiques.
  final String? subline;

  /// Ce que la carte fait quand on la touche. `null` — le défaut — en fait une
  /// carte de lecture : aucune bordure de survol, aucun rôle de bouton annoncé.
  ///
  /// Une carte cliquable est un **filtre** : elle applique ce qu'elle compte.
  final VoidCallback? onTap;

  /// Vrai quand ce filtre est celui qui s'applique. La carte s'enfonce, et
  /// l'assistance vocale l'annonce comme sélectionnée — la couleur seule ne
  /// dirait rien à qui ne la voit pas.
  final bool selected;

  const EteeloKpiCardData({
    required this.label,
    this.value,
    this.valueText,
    this.valueLines,
    required this.accent,
    required this.accentSoft,
    required this.icon,
    this.percent,
    this.subline,
    this.onTap,
    this.selected = false,
    this.filledBackground,
    this.filledSecondaryInk,
  }) : assert(
         value != null || valueText != null || valueLines != null,
         'KpiCardData : fournir value (entier), valueText (formaté) ou '
         'valueLines (plusieurs valeurs à empiler).',
       ),
       assert(
         valueLines == null || valueLines.length > 0,
         'KpiCardData : valueLines vide rendrait une carte muette. Passer '
         'null, ou une ligne disant ce que le vide veut dire.',
       );

  /// Vrai quand la carte se peint en pavé sombre plutôt qu'en carte claire.
  bool get isFilled => filledBackground != null;

  /// Les valeurs à afficher, de haut en bas. Une seule dans le cas courant.
  List<String> get displayValues {
    final lines = valueLines;
    if (lines != null && lines.isNotEmpty) return lines;
    return [displayValue];
  }

  /// Texte affiché pour la valeur (formaté si fourni, sinon l'entier).
  ///
  /// Quand la carte porte plusieurs valeurs, c'est la première — les surfaces
  /// qui n'en attendent qu'une (une clé de widget, un diagnostic) restent
  /// correctes.
  String get displayValue {
    final lines = valueLines;
    if (lines != null && lines.isNotEmpty) return lines.first;
    return valueText ?? '${value ?? ''}';
  }
}
