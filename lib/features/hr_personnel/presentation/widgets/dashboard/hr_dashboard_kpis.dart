import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/helpers/hr_personnel_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Trois chiffres, pas plus — effectif, enseignants, ancienneté moyenne — sur
/// tout le fichier, quels que soient les filtres de la liste.
class HrDashboardKpis extends StatelessWidget {
  final HrStaffStats stats;

  const HrDashboardKpis({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloKpiBand(
      cards: [
        EteeloKpiCardData(
          label: l10n.hrKpiHeadcount,
          value: stats.headcount,
          icon: Icons.groups_outlined,
          accent: AppColors.bleuArdoise,
          accentSoft: AppColors.bleuArdoiseSoft,
          filledBackground: DashboardTones.pave(
            DashboardTones.paveAccentSur(AppColors.bleuArdoise),
          ),
          subline: _sexes(l10n),
        ),
        EteeloKpiCardData(
          label: l10n.hrKpiTeachers,
          value: stats.teachers,
          icon: Icons.school_outlined,
          accent: AppColors.bleuArdoise,
          accentSoft: AppColors.bleuArdoiseSoft,
          subline: l10n.hrKpiTeachersSubline(
            stats.teacherPercent,
            stats.headcount - stats.teachers,
          ),
        ),
        EteeloKpiCardData(
          label: l10n.hrKpiSeniority,
          valueText: _average(l10n),
          icon: Icons.workspace_premium_outlined,
          accent: AppColors.hrSeniorityAccent,
          accentSoft: AppColors.hrSenioritySoft,
          subline: _dean(l10n),
        ),
      ],
    );
  }

  /// « 7 femmes · 7 hommes », et les sexes non renseignés quand il y en a :
  /// la somme doit retomber sur l'effectif affiché au-dessus.
  String _sexes(AppLocalizations l10n) {
    final sexes = stats.sexes;
    final split = l10n.hrJoin(
      l10n.hrCountWomen(sexes.women),
      l10n.hrCountMen(sexes.men),
    );
    return sexes.unknown == 0
        ? split
        : l10n.hrJoin(split, l10n.hrCountSexUnknown(sexes.unknown));
  }

  String _average(AppLocalizations l10n) {
    final average = stats.averageSeniority;
    if (average == null) return l10n.hrKpiSeniorityEmpty;
    return l10n.hrKpiSeniorityValue(HrPersonnelLabels.decimal(l10n, average));
  }

  String _dean(AppLocalizations l10n) {
    final dean = stats.dean;
    if (dean == null) return l10n.hrKpiSeniorityNone;
    final line = l10n.hrKpiSeniorityDean(
      dean.displayName,
      l10n.hrSeniorityYears(dean.years),
    );
    final excluded = stats.headcount - stats.seniorityBase;
    return excluded == 0
        ? line
        : l10n.hrJoin(line, l10n.hrKpiSeniorityExcluded(excluded));
  }
}
