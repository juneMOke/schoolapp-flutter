import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/components/charts/cycle_bar_chart.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/weekday_absence_stat.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/attendance_overview_format.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/attendance_overview_palette.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section « Absences par jour » du tableau de bord des presences.
///
/// Affiche un graphique en barres du taux d'absence par jour de semaine
/// (lundi -> vendredi). La barre du jour de pic (taux d'absence maximal) est en
/// rouge plein ; les autres sont en rouge desature (alpha 0,5) pour mettre le
/// pic en avant. Lecture seule.
class AttendanceOverviewWeekdaySection extends StatelessWidget {
  final List<WeekdayAbsenceStat> weekdays;

  const AttendanceOverviewWeekdaySection({super.key, required this.weekdays});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AttendanceOverviewCard(
      title: l10n.attendanceOverviewWeekdayTitle,
      hint: l10n.attendanceOverviewWeekdayHint,
      child: _buildChild(context, l10n),
    );
  }

  Widget _buildChild(BuildContext context, AppLocalizations l10n) {
    if (weekdays.isEmpty) {
      return _Placeholder(l10n: l10n);
    }

    // Indice du jour de pic (taux d'absence maximal) : barre rouge plein.
    var peakIndex = 0;
    for (var i = 1; i < weekdays.length; i++) {
      if (weekdays[i].absenceRate > weekdays[peakIndex].absenceRate) {
        peakIndex = i;
      }
    }

    final items = <BarChartItem>[
      for (var i = 0; i < weekdays.length; i++)
        BarChartItem(
          label: AttendanceOverviewPalette.weekdayLabel(
            weekdays[i].weekday,
            l10n,
          ),
          value: weekdays[i].absenceRate,
          // Pic = rouge plein ; autres jours = rouge desature pour le contraste.
          color: i == peakIndex
              ? AppColors.error
              : AppColors.error.withValues(alpha: 0.5),
        ),
    ];

    // Resume textuel pour l'accessibilite (l'info ne repose pas sur la couleur).
    final a11ySummary = items
        .map(
          (item) =>
              '${item.label} : ${l10n.attendanceOverviewRateValue(AttendanceOverviewFormat.rate(item.value, context))}',
        )
        .join(', ');

    return Semantics(
      label: '${l10n.attendanceOverviewWeekdayTitle}. $a11ySummary',
      child: ExcludeSemantics(
        child: CycleBarChart(
          items: items,
          highlightedIndexes: {peakIndex},
          showValueLabels: true,
          valueLabelFormatter: (value) => l10n.attendanceOverviewRateValue(
            AttendanceOverviewFormat.rate(value, context),
          ),
          // Spec : étiquette rouge sur le pic, neutre (gris) sur les autres jours.
          valueLabelColorBuilder: (index) =>
              index == peakIndex ? AppColors.error : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Placeholder discret affiche lorsqu'aucune donnee par jour n'est disponible.
class _Placeholder extends StatelessWidget {
  final AppLocalizations l10n;

  const _Placeholder({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
      child: Text(
        l10n.attendanceOverviewEmptyDescription,
        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}
