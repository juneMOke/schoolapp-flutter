import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/selection/checkable_row.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'encadré de O3 qui rappelle CAL-R8 (maquette CalDuplicateModal) : fond
/// neutre ; le cadre de l'année visée, intégré (cadenas) ou attendu (horloge,
/// ambre) ; le brouillon, et ce que devient la source.
class DuplicateCalendarNotice extends StatelessWidget {
  final String sourceYear;
  final String targetYear;
  final FrameworkState? targetFramework;
  final bool sourceInForce;

  const DuplicateCalendarNotice({
    super.key,
    required this.sourceYear,
    required this.targetYear,
    required this.targetFramework,
    required this.sourceInForce,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final awaited = targetFramework == FrameworkState.awaited;
    final style = AppTypography.bodySmall.copyWith(
      color: AppColors.textSecondary,
    );
    final frameworkInk = awaited ? AppColors.staffPartialInk : style.color;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.schoolCalendarDuplicateShift, style: style),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  awaited ? Icons.schedule_rounded : Icons.lock_outline,
                  size: 13,
                  color: frameworkInk,
                ),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Text(
                  l10n.schoolCalendarDuplicateFramework(
                    targetFramework?.name ?? '',
                    targetYear,
                  ),
                  style: style.copyWith(color: frameworkInk),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.schoolCalendarDuplicateDraft(
              sourceInForce ? 'inForce' : 'other',
              sourceYear,
            ),
            style: style,
          ),
        ],
      ),
    );
  }
}

/// Le cadre de l'année choisie : bleu s'il est publié, ambre s'il est
/// attendu (maquette CalCreateModal).
class CalendarFrameworkNotice extends StatelessWidget {
  final String year;
  final bool integrated;

  const CalendarFrameworkNotice({
    super.key,
    required this.year,
    required this.integrated,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return integrated
        ? EteeloNotice.tinted(
            message: l10n.schoolCalendarNewFrameworkReady(year),
            icon: Icons.lock_outline,
            ink: AppColors.bleuArdoise,
            background: AppColors.bleuArdoiseSoft,
          )
        : EteeloNotice.tinted(
            message: l10n.schoolCalendarNewFrameworkAwaited(year),
            icon: Icons.schedule_rounded,
            ink: AppColors.staffPartialInk,
            background: AppColors.feeStatusPartialSoft,
          );
  }
}

/// Une case à cocher en tuile (maquette CalDuplicateModal) : bordée d'ardoise
/// quand elle est cochée ; toute la tuile répond à l'appui.
class CalendarCheckTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String detail;

  const CalendarCheckTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: value ? AppColors.bleuArdoiseSoft : AppColors.surfaceRaised,
      borderRadius: AppRadius.brMd,
      border: Border.all(
        color: value ? AppColors.bleuArdoise : AppColors.border,
        width: 1.5,
      ),
    ),
    child: CheckableRow(
      value: value,
      onChanged: onChanged,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              activeColor: AppColors.bleuArdoise,
              onChanged: (v) => onChanged(v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm + 2,
                  right: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleSmall),
                    Text(
                      detail,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
