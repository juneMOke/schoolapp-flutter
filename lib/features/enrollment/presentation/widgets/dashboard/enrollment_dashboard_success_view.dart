import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/motion/eteelo_entrance.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_dashboard_kpi_band.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_day_entries_section.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_export_actions.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_insights_section.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_pace_section.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_where_sections.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_who_sections.dart';

/// L'empilement du tableau de bord, dans un ordre qui raconte.
///
/// **Combien → quand → qui → où → quoi en faire.** L'ordre n'est pas une
/// préférence de mise en page : c'est la façon dont on lit un effectif. Les
/// chiffres clés répondent d'abord à « combien », le rythme à « quand », les
/// deux barres à « qui », les lignes-barres à « où », et les cartes de lecture
/// disent ce que tout cela suggère.
///
/// Le bandeau d'effectif, lui, est rendu **au-dessus** par la page : il survit
/// à l'état vide, ce qui n'est pas le cas de cette grille.
///
/// La liste nominative du jour s'insère entre « où » et « lectures », mais
/// **seulement quand la fenêtre couvre une seule journée**. Au-delà elle est
/// masquée, pas paginée à l'infini : une liste de noms sur une année n'est pas
/// une lecture de tableau de bord.
class EnrollmentDashboardSuccessView extends StatelessWidget {
  final EnrollmentStats stats;

  /// Le libellé de la fenêtre, pour titrer la première carte.
  final String windowLabel;

  /// Vrai quand la fenêtre couvre une seule journée : les sous-titres passent
  /// de « de la période » à « du jour ».
  final bool isSingleDay;

  final void Function(LevelStat level)? onLevelTap;
  final VoidCallback? onOpenPreRegistrations;

  /// Ouvre le dossier d'un élève depuis la liste du jour.
  final void Function(DayEnrollmentEntry entry)? onDayEntryTap;

  const EnrollmentDashboardSuccessView({
    super.key,
    required this.stats,
    required this.windowLabel,
    required this.isSingleDay,
    this.onLevelTap,
    this.onOpenPreRegistrations,
    this.onDayEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // COMBIEN
        EteeloEntrance(
          index: 0,
          child: EnrollmentDashboardKpiBand(
            kpis: stats.kpis,
            windowLabel: windowLabel,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        // QUAND
        EteeloEntrance(
          index: 1,
          child: EnrollmentPaceSection(evolution: stats.evolution),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        // QUI
        EteeloEntrance(
          index: 2,
          child: _Pair(
            start: EnrollmentGenderSection(
              windowDistribution: stats.distributionByGender,
              headcount: stats.headcount,
              isSingleDay: isSingleDay,
            ),
            end: EnrollmentTypeSection(
              kpis: stats.kpis,
              isSingleDay: isSingleDay,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        // OÙ
        EteeloEntrance(
          index: 3,
          child: EnrollmentLevelSection(
            distribution: stats.distributionByCycle,
            isSingleDay: isSingleDay,
            onLevelTap: onLevelTap,
            // La carte retire elle-même ces boutons quand aucun niveau n'a
            // reçu d'inscription : un PDF d'un tableau vide est une page
            // blanche.
            //
            // Le `Builder` donne au bouton un contexte situé SOUS le
            // `Scaffold` : le toast d'échec a besoin d'un `ScaffoldMessenger`,
            // et le contexte de cette vue est au-dessus.
            exportActions: [
              Builder(
                builder: (context) => EnrollmentExportActions.levelsPdf(
                  context: context,
                  levels: EnrollmentLevelSection.levelsOf(
                    stats.distributionByCycle,
                  ),
                  schoolYear: stats.context.schoolYear,
                  generatedAt: stats.context.generatedAt,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        EteeloEntrance(
          index: 4,
          child: EnrollmentCycleSection(
            distribution: stats.distributionByCycle,
          ),
        ),
        // QUI EXACTEMENT — sur une seule journée uniquement.
        //
        // La condition est portée ici et pas dans la carte : au-delà d'un
        // jour, le sous-arbre n'existe pas du tout, donc le second appel n'a
        // aucun point de montage d'où partir.
        if (isSingleDay) ...[
          const SizedBox(height: AppDimensions.spacingL),
          EteeloEntrance(
            index: 5,
            child: EnrollmentDayEntriesSection(onEntryTap: onDayEntryTap),
          ),
        ],
        const SizedBox(height: AppDimensions.spacingL),
        // QUOI EN FAIRE
        EteeloEntrance(
          index: 6,
          child: EnrollmentInsightsSection(
            stats: stats,
            onOpenPreRegistrations: onOpenPreRegistrations,
          ),
        ),
      ],
    );
  }
}

/// Deux cartes à parts égales, empilées quand la largeur ne suffit plus.
class _Pair extends StatelessWidget {
  final Widget start;
  final Widget end;

  const _Pair({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.attendanceOverviewTwoColMin) {
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
            Expanded(child: start),
            const SizedBox(width: AppDimensions.spacingL),
            Expanded(child: end),
          ],
        );
      },
    );
  }
}
