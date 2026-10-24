import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_kpis.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Quatre chiffres sur la période : le taux de présence, les retards, les
/// absences non justifiées puis justifiées.
///
/// Un sens, une couleur, sur tous les tableaux de bord : le taux est vert
/// (`encaisse`, comme à l'appel des élèves — F1), les retards ocre, les
/// absences non justifiées rouges, les justifiées bleu ardoise (`attendu`,
/// une absence n'est pas « conforme » — F2).
class HrPresenceKpis extends StatelessWidget {
  final HrAttendanceKpis kpis;

  const HrPresenceKpis({super.key, required this.kpis});

  static EteeloKpiCardData _card({
    required String label,
    required IconData icon,
    required Color accent,
    required String subline,
    int? value,
    String? valueText,
  }) => EteeloKpiCardData(
    label: label,
    value: value,
    valueText: valueText,
    icon: icon,
    accent: accent,
    accentSoft: DashboardTones.teinte(accent, DashboardTones.zebrurePercent),
    filledBackground: DashboardTones.pave(DashboardTones.paveAccentSur(accent)),
    subline: subline,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rate = kpis.presenceRatePct;
    final punctuality = kpis.punctualityPct;
    return Semantics(
      container: true,
      label: l10n.hrPresenceKpisA11y,
      child: EteeloKpiBand(
        cards: [
          _card(
            label: l10n.hrPresenceKpiRate,
            // Rien de pointé : « — », jamais un « 0 % » qui accuserait.
            valueText: rate == null
                ? l10n.hrPresenceNoValue
                : l10n.presenceRateValue(rate),
            icon: Icons.how_to_reg_outlined,
            accent: DashboardSense.encaisse,
            subline: l10n.hrPresenceKpiRateSubline(kpis.presences, kpis.scored),
          ),
          _card(
            label: l10n.hrPresenceKpiLate,
            value: kpis.late,
            icon: Icons.schedule,
            accent: DashboardSense.attente,
            subline: punctuality == null
                ? l10n.hrPresenceMinutes(kpis.lateMinutes)
                : l10n.hrPresenceKpiLateSubline(kpis.lateMinutes, punctuality),
          ),
          _card(
            label: l10n.hrPresenceKpiUnjustified,
            value: kpis.unjustifiedAbsences,
            icon: Icons.cancel_outlined,
            accent: DashboardSense.manquant,
            // E3 : signalées, jamais retenues sur la paie.
            subline: l10n.hrPresenceKpiUnjustifiedSubline,
          ),
          _card(
            label: l10n.hrPresenceKpiJustified,
            value: kpis.justifiedAbsences,
            icon: Icons.event_note_outlined,
            accent: DashboardSense.attendu,
            subline: l10n.hrPresenceKpiJustifiedSubline,
          ),
        ],
      ),
    );
  }
}
