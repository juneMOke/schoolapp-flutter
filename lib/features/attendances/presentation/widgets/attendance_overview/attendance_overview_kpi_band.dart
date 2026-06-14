import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_kpis.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/attendance_overview_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bande de 4 cartes KPI du tableau de bord des presences (echelle ecole).
///
/// Lecture seule. Les trois premieres cartes (presence / absence justifiee /
/// absence injustifiee) affichent un taux formate ([EteeloKpiCardData.valueText])
/// et totalisent 100 %. La quatrieme carte affiche le nombre de jours
/// enregistres en valeur entiere ([EteeloKpiCardData.value]). Chaque carte porte
/// une sous-ligne discrete en « eleve-jours ».
class AttendanceOverviewKpiBand extends StatelessWidget {
  final AttendanceKpis kpis;

  const AttendanceOverviewKpiBand({super.key, required this.kpis});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Sous-ligne « N eleve-jours » : reutilise le format compteur localise
    // (separateur de milliers fr/en).
    String studentDays(int days) => l10n.attendanceOverviewStudentDays(
      AttendanceOverviewFormat.count(days, context),
    );

    // Valeur de taux deja formatee (1 decimale, separateur localise).
    String rateValue(double rate) => l10n.attendanceOverviewRateValue(
      AttendanceOverviewFormat.rate(rate, context),
    );

    final cards = <EteeloKpiCardData>[
      // 1. Taux de presence.
      EteeloKpiCardData(
        label: l10n.attendanceOverviewKpiPresence,
        valueText: rateValue(kpis.presenceRate),
        accent: AppColors.vertSavane,
        accentSoft: AppColors.presenceStatePresentSoft,
        icon: Icons.check_rounded,
        subline: studentDays(kpis.presentDays),
      ),
      // 2. Taux d'absence justifiee.
      EteeloKpiCardData(
        label: l10n.attendanceOverviewKpiJustified,
        valueText: rateValue(kpis.justifiedAbsenceRate),
        accent: AppColors.warning,
        accentSoft: AppColors.presenceStateJustifiedSoft,
        icon: Icons.event_busy_outlined,
        subline: studentDays(kpis.justifiedAbsenceDays),
      ),
      // 3. Taux d'absence injustifiee.
      EteeloKpiCardData(
        label: l10n.attendanceOverviewKpiUnjustified,
        valueText: rateValue(kpis.unjustifiedAbsenceRate),
        accent: AppColors.error,
        accentSoft: AppColors.presenceStateUnjustifiedSoft,
        icon: Icons.block,
        subline: studentDays(kpis.unjustifiedAbsenceDays),
      ),
      // 4. Jours enregistres (compteur entier, pas de taux).
      EteeloKpiCardData(
        label: l10n.attendanceOverviewKpiRecordedDays,
        value: kpis.recordedDays,
        accent: AppColors.bleuArdoise,
        accentSoft: AppColors.attendanceOverviewRecordedSoft,
        icon: Icons.calendar_month_outlined,
        subline: studentDays(
          kpis.presentDays +
              kpis.justifiedAbsenceDays +
              kpis.unjustifiedAbsenceDays,
        ),
      ),
    ];

    // Conteneur semantique : l'intitule global decrit la bande pour les
    // lecteurs d'ecran (info portee par le texte des cartes, pas la couleur).
    return Semantics(
      container: true,
      label: l10n.attendanceOverviewKpiBandA11yLabel,
      child: EteeloKpiBand(cards: cards),
    );
  }
}
