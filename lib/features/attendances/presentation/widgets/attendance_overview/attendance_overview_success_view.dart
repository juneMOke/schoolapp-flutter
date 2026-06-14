import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_overview.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_by_class_table.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_evolution_section.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_kpi_band.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_reasons_section.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_split_bar.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_top_absent_section.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_weekday_section.dart';

/// Grille analytique du tableau de bord (cas nominal `recordedDays >= 1`).
///
/// La barre de contexte est rendue par la page au-dessus (toujours visible).
class AttendanceOverviewSuccessView extends StatelessWidget {
  final AttendanceOverview overview;

  const AttendanceOverviewSuccessView({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AttendanceOverviewKpiBand(kpis: overview.kpis),
        const SizedBox(height: AppDimensions.spacingL),
        AttendanceOverviewSplitBar(kpis: overview.kpis),
        const SizedBox(height: AppDimensions.spacingL),
        _ResponsivePair(
          startFlex: 2,
          endFlex: 1,
          // Seuil plus haut : le donut Motifs (1fr) ne doit pas être comprimé.
          twoColMin: AppBreakpoints.attendanceOverviewWideTwoColMin,
          start: AttendanceOverviewEvolutionSection(
            evolution: overview.evolution,
          ),
          end: AttendanceOverviewReasonsSection(
            reasons: overview.byAbsenceReason,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _ResponsivePair(
          startFlex: 1,
          endFlex: 1,
          start: AttendanceOverviewWeekdaySection(weekdays: overview.byWeekday),
          end: AttendanceOverviewTopAbsentSection(
            classes: overview.topAbsentClasses,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        AttendanceOverviewByClassTable(classes: overview.byClass),
        const SizedBox(height: AppDimensions.spacingXL),
      ],
    );
  }
}

/// Deux panneaux côte à côte au-delà de [AppBreakpoints.attendanceOverviewTwoColMin],
/// empilés en colonne en deçà.
class _ResponsivePair extends StatelessWidget {
  final Widget start;
  final Widget end;
  final int startFlex;
  final int endFlex;
  final double twoColMin;

  const _ResponsivePair({
    required this.start,
    required this.end,
    required this.startFlex,
    required this.endFlex,
    this.twoColMin = AppBreakpoints.attendanceOverviewTwoColMin,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < twoColMin) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              start,
              const SizedBox(height: AppDimensions.spacingL),
              end,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: startFlex, child: start),
            const SizedBox(width: AppDimensions.spacingL),
            Expanded(flex: endFlex, child: end),
          ],
        );
      },
    );
  }
}
