import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_dashed_border.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/school_calendar_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar_date_chip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La carte de dates du détail (maquette CalItemModal) : pastille du début,
/// flèche, pastille de la fin, la durée et où en est l'élément ; trait plein
/// pour un élément national, tirets pour un élément de l'école (CAL-R4).
class ElementDateCard extends StatelessWidget {
  final CalendarElement element;
  final DateTime today;

  const ElementDateCard({
    super.key,
    required this.element,
    required this.today,
  });

  /// « En cours », « Terminé », « Demain », « Dans 5 jours ».
  static String when(AppLocalizations l10n, CalendarElement e, DateTime today) {
    final day = CalendarDays.of(today);
    if (e.endDate.isBefore(day)) return l10n.schoolCalendarWhen('past');
    if (!e.startDate.isAfter(day)) return l10n.schoolCalendarWhen('now');
    return l10n.schoolCalendarDetailInDays(
      CalendarDays.between(day, e.startDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = element.nature.tone;
    final dashed = SchoolCalendarTones.isDashed(isNational: element.isNational);
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          CalendarDateChip(
            date: element.startDate,
            tone: tone,
            strong: true,
            size: AppDimensions.calendarDateChipLarge,
          ),
          if (!element.isSingleDay) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.arrow_forward_rounded, size: 16, color: tone.tone),
            const SizedBox(width: AppSpacing.sm),
            CalendarDateChip(
              date: element.endDate,
              tone: tone,
              size: AppDimensions.calendarDateChipLarge,
            ),
          ],
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.schoolCalendarDurationDays(element.durationDays),
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.bleuProfond,
                  ),
                ),
                Text(
                  when(l10n, element, today),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (element.toVerify) ...[
            const SizedBox(width: AppSpacing.sm),
            StatusBadge(
              icon: Icons.warning_amber_rounded,
              label: l10n.schoolCalendarToVerify,
              color: AppColors.warningInk,
              size: StatusBadgeSize.small,
            ),
          ],
        ],
      ),
    );
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brLg,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.soft, AppColors.surfaceRaised],
        ),
        border: dashed
            ? null
            : Border.all(color: tone.tone.withValues(alpha: 0.4)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: AppDimensions.calendarDetailAccentWidth,
              color: tone.tone,
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
    return ClipRRect(
      borderRadius: AppRadius.brLg,
      child: dashed
          ? CustomPaint(
              foregroundPainter: DashedRRectPainter(
                color: tone.tone,
                borderRadius: AppRadius.brLg,
                strokeWidth: 1.5,
              ),
              child: card,
            )
          : card,
    );
  }
}

/// Une tuile « libellé / valeur » des faits du détail.
class ElementFactTile extends StatelessWidget {
  final String label;
  final Widget value;

  const ElementFactTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadius.brMd,
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        DefaultTextStyle.merge(
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          child: value,
        ),
      ],
    ),
  );
}

/// Les tuiles en grille de deux colonnes ; la première prend toute la ligne.
class ElementFactGrid extends StatelessWidget {
  final List<ElementFactTile> tiles;

  const ElementFactGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) return const SizedBox.shrink();
    final rest = tiles.skip(1).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tiles.first,
        for (var i = 0; i < rest.length; i += 2) ...[
          const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: rest[i]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: i + 1 < rest.length
                      ? rest[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// « Cadre national » (cadenas) ou « Interne » (crayon), comme la source
/// d'une ligne.
class ElementSourceValue extends StatelessWidget {
  final bool national;

  const ElementSourceValue({super.key, required this.national});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = national ? AppColors.bleuProfond : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          national ? SchoolCalendarTones.nationalIcon : Icons.edit_outlined,
          size: 13,
          color: color,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            national
                ? l10n.schoolCalendarNationalFramework
                : l10n.schoolCalendarInternal,
            style: TextStyle(color: color),
          ),
        ),
      ],
    );
  }
}

/// La mention du cadre national, en texte discret précédé du cadenas.
class ElementNationalMention extends StatelessWidget {
  final String text;

  const ElementNationalMention(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Icon(
          SchoolCalendarTones.nationalIcon,
          size: 14,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    ],
  );
}
