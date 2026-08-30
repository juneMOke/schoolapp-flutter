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

  /// Sous-ligne optionnelle affichee sous la valeur (ex. « 510 eleve-jours »).
  /// Rendue en caption discrete ; les cartes qui en ont sont legerement plus
  /// hautes ([AppDimensions.kpiCardHeightWithSubline]) — celles qui n'en ont
  /// pas conservent le rendu et la hauteur historiques.
  final String? subline;

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
