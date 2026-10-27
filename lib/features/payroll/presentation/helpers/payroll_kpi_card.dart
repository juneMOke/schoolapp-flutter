import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';

/// Un chiffre clé de la paie, **en pavé plein** comme sur les autres tableaux
/// de bord (Boutique, RH · Présences) : l'accent dit le sens, la formule
/// partagée [DashboardTones.pave] le fond, et une seconde devise s'écrit dans
/// sa nuance d'encre.
abstract final class PayrollKpiCard {
  static EteeloKpiCardData of({
    required String label,
    required IconData icon,
    required Color accent,
    List<String>? valueLines,
    String? valueText,
    int? value,
    String? subline,
    VoidCallback? onTap,
    bool selected = false,
  }) {
    final fond = DashboardTones.paveAccentSur(accent);
    return EteeloKpiCardData(
      label: label,
      value: value,
      valueText: valueText,
      valueLines: valueLines,
      icon: icon,
      accent: accent,
      accentSoft: DashboardTones.teinte(accent, DashboardTones.zebrurePercent),
      filledBackground: DashboardTones.pave(fond),
      filledSecondaryInk: DashboardTones.encreSecondeValeur(fond),
      subline: subline,
      onTap: onTap,
      selected: selected,
    );
  }
}
