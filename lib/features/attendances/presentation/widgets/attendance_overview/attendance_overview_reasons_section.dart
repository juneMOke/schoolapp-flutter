import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/gender_donut_chart.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/absence_reason_stats.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/attendance_overview_palette.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section « Motifs d'absence » du tableau de bord des presences.
///
/// Affiche la repartition des jours d'absence par motif sous forme d'anneau
/// (donut). Le regroupement metier (UNKNOWN / null / non justifie reunis en un
/// seul segment rouge « Non justifie », autres motifs tries par effectif
/// decroissant) est entierement gere en amont par
/// [AttendanceOverviewPalette.reasonDonut].
class AttendanceOverviewReasonsSection extends StatelessWidget {
  final List<AbsenceReasonStats> reasons;

  const AttendanceOverviewReasonsSection({super.key, required this.reasons});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final donut = AttendanceOverviewPalette.reasonDonut(reasons, l10n);

    final hasData = donut.total > 0 && donut.sections.isNotEmpty;

    return AttendanceOverviewCard(
      title: l10n.attendanceOverviewReasonsTitle,
      hint: l10n.attendanceOverviewReasonsHint,
      child: hasData
          // Le donut rend lui-meme le total central + une legende textuelle
          // (libelle + effectif + %), donc l'information n'est pas portee par
          // la couleur seule (accessibilite).
          ? Semantics(
              label: l10n.attendanceOverviewReasonsTitle,
              child: GenderDonutChart(
                sections: donut.sections,
                total: donut.total,
                centerLabel: l10n.attendanceOverviewReasonsCenterLabel,
                centerSpaceRadius:
                    AppDimensions.attendanceOverviewDonutCenterRadius,
                sectionRadius:
                    AppDimensions.attendanceOverviewDonutRingThickness,
                // Le panneau Motifs est étroit (1fr) : bascule en donut + légende
                // listée (motif·%·effectif) dès ~300 dp, sans attendre 760.
                compactBelow: AppBreakpoints.reasonDonutRowMin,
                // Total central conforme à la spec (24 dp, bleu-ardoise, tnum).
                centerValueStyle: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bleuArdoise,
                ),
              ),
            )
          : _ReasonsEmptyPlaceholder(
              message: l10n.attendanceOverviewEmptyDescription,
            ),
    );
  }
}

/// Placeholder discret affiche lorsqu'aucune absence n'est enregistree.
class _ReasonsEmptyPlaceholder extends StatelessWidget {
  final String message;

  const _ReasonsEmptyPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingL),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
