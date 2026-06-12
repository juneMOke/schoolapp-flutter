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

  final int? percent;
  final Color accent;
  final Color accentSoft;
  final IconData icon;

  const EteeloKpiCardData({
    required this.label,
    this.value,
    this.valueText,
    required this.accent,
    required this.accentSoft,
    required this.icon,
    this.percent,
  }) : assert(
         value != null || valueText != null,
         'KpiCardData : fournir value (entier) ou valueText (formaté).',
       );

  /// Texte affiché pour la valeur (formaté si fourni, sinon l'entier).
  String get displayValue => valueText ?? '${value ?? ''}';
}
