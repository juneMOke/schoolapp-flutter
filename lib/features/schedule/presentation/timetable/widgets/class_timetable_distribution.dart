import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/course_domain_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_timetable_distribution_parts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La répartition hebdomadaire (EDT §4.6 F), toujours sous la grille : une
/// carte par cours — nom, « 4/6 h » (vert si conforme, ambre sinon), une
/// barre d'un segment par heure au ton du domaine, l'enseignant. Survoler ou
/// focaliser une carte repère le cours dans la grille (I5) ; la légende des
/// domaines, teintée, filtre la page (I6), « Tous les domaines » l'efface.
class ClassTimetableDistribution extends StatelessWidget {
  final ClassTimetableView view;
  final List<ClassTimetableCell> cells;

  /// Le cours repéré, et le survol d'une carte (`null` en sortant).
  final String? linkedCoursId;
  final ValueChanged<String?>? onHoverCours;

  /// L'aide (« survolez » à la souris, « touchez » au doigt) ; `null` :
  /// aucune, en vue Jour où il n'y a pas de grille.
  final String? hint;

  /// Le domaine filtré (`null` : tous), et le toucher d'un domaine.
  final String? domainFilter;
  final ValueChanged<String?>? onDomainFilter;

  const ClassTimetableDistribution({
    super.key,
    required this.view,
    required this.cells,
    this.linkedCoursId,
    this.onHoverCours,
    this.hint,
    this.domainFilter,
    this.onDomainFilter,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final order = view.domainOrder;
    final counts = <String, int>{};
    for (final c in cells) {
      final id = c.coursId;
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }
    // La légende suit l'ordre des teintes (D10), pas celui du programme.
    final labels = <String, String>{
      for (final c in view.programme)
        ?c.domainId: c.domainLabel ?? c.domainId ?? '',
    };
    final domains = {
      for (final id in [
        ...order.where(labels.containsKey),
        ...labels.keys.where((id) => !order.contains(id)),
      ])
        id: labels[id]!,
    };
    final hover = onHoverCours;
    final filter = onDomainFilter;
    final hint = this.hint;
    final linked = linkedCoursId;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brLg,
        border: Border.all(
          color: ColorMix.tint(
            AppColors.border,
            AppColors.bleuArdoise,
            AppDimensions.timetableDistributionBorderPercent,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, AppDimensions.timetableDistributionGlowStop],
          colors: [
            ColorMix.tint(
              AppColors.surfaceRaised,
              AppColors.bleuArdoise,
              AppDimensions.timetableDistributionGlowPercent,
            ),
            AppColors.surfaceRaised,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DistributionHeader(
            title: l10n.classTimetableDistribution,
            subtitle: [
              l10n.classTimetableDistributionSubtitle,
              ?hint,
            ].join(' · '),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppSpacing.sm;
              final columns =
                  ((constraints.maxWidth + gap) /
                          (AppDimensions.timetableDistributionCardMinWidth +
                              gap))
                      .floor()
                      .clamp(1, 99);
              final width =
                  ((constraints.maxWidth - gap * (columns - 1)) / columns)
                      .floorToDouble();
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final course in view.programme)
                    SizedBox(
                      width: width,
                      child: DistributionCard(
                        course: course,
                        tone: CourseDomainTones.forDomain(
                          course.domainId,
                          order,
                        ),
                        placed: counts[course.coursId] ?? 0,
                        linked: linked == course.coursId,
                        dimmed:
                            (domainFilter != null &&
                                course.domainId != domainFilter) ||
                            (linked != null && linked != course.coursId),
                        onHover: hover == null
                            ? null
                            : (inside) => hover(inside ? course.coursId : null),
                      ),
                    ),
                ],
              );
            },
          ),
          if (filter != null && domains.length > 1) ...[
            const SizedBox(height: AppSpacing.xs),
            DomainLegend(
              domains: domains,
              order: order,
              selected: domainFilter,
              onSelected: filter,
              clearLabel: l10n.classTimetableAllDomains,
            ),
          ],
        ],
      ),
    );
  }
}
