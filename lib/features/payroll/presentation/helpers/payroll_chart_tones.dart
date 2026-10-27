import 'package:flutter/painting.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Les teintes des graphiques de la paie, toutes prises aux sens partagés
/// ([DashboardSense]) : un versement est vert, un manque rouge, une attente
/// ocre, un dû structurel bleu ardoise — comme sur les autres tableaux de
/// bord. Chaque segment est aussi écrit dans sa légende : la couleur ne porte
/// jamais seule l'information.
abstract final class PayrollChartTones {
  // ── Ce qui sépare le brut du net ──
  static const Color net = DashboardSense.encaisse;
  static const Color absence = DashboardSense.manquant;
  static const Color advances = DashboardSense.attente;
  static const Color legal = DashboardSense.attendu;
  static const Color childcare = DashboardSense.marque;

  // ── Où en est le net ──
  static const Color paid = DashboardSense.encaisse;
  static const Color deferred = DashboardSense.attendu;
  static const Color unpaid = DashboardSense.manquant;

  /// Un net d'un mois pas encore validé : rien n'est dû, rien n'est en retard.
  static const Color notYet = AppColors.textMuted;
}
