import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/theme/course_domain_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La répartition hebdomadaire (EDT §4.6 F) : une ligne par cours, à la
/// teinte de son domaine, avec ses heures placées (et prévues, si connues).
/// Survoler ou focaliser une ligne repère le cours dans la grille (I5) ; la
/// légende des domaines, dessous, filtre la page (I6).
class ClassTimetableDistribution extends StatelessWidget {
  final ClassTimetableView view;
  final List<ClassTimetableCell> cells;

  /// Le cours repéré, et le survol d'une ligne (`null` en sortant).
  final String? linkedCoursId;
  final ValueChanged<String?>? onHoverCours;

  /// L'aide au-dessus des lignes (« Survolez » à la souris, « Touchez » au
  /// doigt) ; `null` : aucune, en vue Jour où il n'y a pas de grille.
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
    final domains = <String, String>{
      for (final c in view.programme)
        ?c.domainId: c.domainLabel ?? c.domainId ?? '',
    };
    final hover = onHoverCours;
    final filter = onDomainFilter;
    return EteeloPanelCard(
      title: l10n.classTimetableDistribution,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hint case final hint?)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(hint, style: AppTypography.bodySmall),
            ),
          for (final course in view.programme)
            if (domainFilter == null || course.domainId == domainFilter)
              _Line(
                course: course,
                tone: CourseDomainTones.forDomain(course.domainId, order),
                placed: counts[course.coursId] ?? 0,
                linked: linkedCoursId == course.coursId,
                onHover: hover == null
                    ? null
                    : (inside) => hover(inside ? course.coursId : null),
              ),
          if (filter != null && domains.length > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                EteeloFilterChip(
                  label: l10n.classTimetableAllDomains,
                  selected: domainFilter == null,
                  color: AppColors.textSecondary,
                  soft: AppColors.surfaceRaised,
                  ink: AppColors.textPrimary,
                  onTap: () => filter(null),
                ),
                for (final MapEntry(key: id, value: label) in domains.entries)
                  () {
                    final tone = CourseDomainTones.forDomain(id, order);
                    return EteeloFilterChip(
                      label: label,
                      selected: domainFilter == id,
                      color: tone.ink,
                      soft: tone.soft,
                      ink: tone.strong,
                      // Le toucher à nouveau annule (I6).
                      onTap: () => filter(domainFilter == id ? null : id),
                    );
                  }(),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final TimetableCourse course;
  final CourseDomainTone tone;
  final int placed;
  final bool linked;
  final ValueChanged<bool>? onHover;

  const _Line({
    required this.course,
    required this.tone,
    required this.placed,
    required this.linked,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final planned = course.weeklyHours;
    final conform = planned == null || planned == placed;
    final hover = onHover;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        borderRadius: AppRadius.brSm,
        onHover: hover,
        onFocusChange: hover,
        // Au doigt, toucher une ligne la repère ou la libère.
        onTap: hover == null ? null : () => hover(!linked),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: linked ? tone.soft : null,
            borderRadius: AppRadius.brSm,
          ),
          child: Row(
            children: [
              Container(
                width: AppSpacing.xs,
                height: AppSpacing.xl,
                decoration: BoxDecoration(
                  color: tone.ink,
                  borderRadius: AppRadius.brSm,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.branchLabel, style: AppTypography.bodyMedium),
                    if (course.teacherLabel case final teacher?)
                      Text(teacher, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              Text(
                planned == null
                    ? l10n.classTimetableHoursPlaced(placed)
                    : l10n.classTimetableHoursOf(placed, planned),
                maxLines: 1,
                softWrap: false,
                style: AppTypography.labelMedium.copyWith(
                  color: conform ? AppColors.vertSavane : AppColors.ambreInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
