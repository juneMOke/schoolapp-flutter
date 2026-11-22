import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/school_calendar_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/month/calendar_dashed_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une puce de la légende (maquette `CalDetail`, `legend`) : un carré de la
/// couleur de la nature, le libellé et le compteur en chiffres fixes. Montrée,
/// elle prend un fond doux de sa nature ; masquée, elle s'estompe, son carré
/// se vide et son libellé se barre. Au doigt ([touch]), 40 dp de haut dans
/// une cible de 48.
class CalendarLegendChip extends StatelessWidget {
  final String label;
  final int count;
  final bool shown;
  final CalendarNature nature;
  final bool touch;
  final VoidCallback onTap;

  const CalendarLegendChip({
    super.key,
    required this.label,
    required this.count,
    required this.shown,
    required this.nature,
    required this.touch,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tone = nature.tone;
    final ink = shown ? tone.ink : AppColors.textMuted;
    final decoration = shown ? null : TextDecoration.lineThrough;
    final chip = Opacity(
      opacity: shown ? 1 : AppDimensions.calendarLegendStrikeOpacity,
      child: Container(
        constraints: BoxConstraints(
          minHeight: touch
              ? AppDimensions.calendarLegendChipTouchHeight
              : AppDimensions.calendarLegendChipHeight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.calendarLegendChipPaddingH,
        ),
        decoration: BoxDecoration(
          color: shown ? tone.soft : AppColors.surface,
          borderRadius: AppRadius.brPill,
          border: Border.all(
            color: shown
                ? tone.tone.withValues(
                    alpha: AppDimensions.calendarLegendBorderOpacity,
                  )
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppDimensions.calendarLegendSwatch,
              height: AppDimensions.calendarLegendSwatch,
              decoration: BoxDecoration(
                color: shown ? tone.tone : Colors.transparent,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppDimensions.calendarLegendSwatchRadius),
                ),
                border: shown
                    ? null
                    : Border.all(
                        color: tone.tone,
                        width: AppDimensions.calendarBandInternalStroke,
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs + AppSpacing.xs / 2),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: AppTypography.labelMedium.copyWith(
                color: ink,
                fontWeight: shown ? FontWeight.w600 : FontWeight.w500,
                decoration: decoration,
                decorationColor: ink,
              ),
            ),
            const SizedBox(width: AppSpacing.xs + AppSpacing.xs / 2),
            Opacity(
              opacity: AppDimensions.calendarLegendStrikeOpacity,
              child: Text(
                '$count',
                style: AppTypography.calendarCount.copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      toggled: shown,
      label: '$label, $count',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: touch
              ? ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppDimensions.minTouchTarget,
                  ),
                  child: Align(widthFactor: 1, child: chip),
                )
              : chip,
        ),
      ),
    );
  }
}

/// La clé des sources (CAL-R4) : national plein avec un cadenas, interne en
/// tirets. En [compact], des traits comme ceux du mois compact, « plein » et
/// « tirets » écrits.
class CalendarSourceKey extends StatelessWidget {
  final bool compact;

  const CalendarSourceKey({super.key, required this.compact});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = AppTypography.labelSmall.copyWith(color: AppColors.textMuted);
    const width = AppDimensions.calendarKeySwatchWidth;
    final national = compact
        ? Container(
            width: width,
            height: AppDimensions.calendarKeyLineHeight,
            decoration: const BoxDecoration(
              color: AppColors.bleuArdoise,
              borderRadius: AppRadius.brPill,
            ),
          )
        : Container(
            width: width,
            height: AppDimensions.calendarKeySwatchHeight,
            decoration: const BoxDecoration(
              color: AppColors.bleuArdoiseSoft,
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(
                  AppDimensions.calendarLegendSwatchRadius,
                ),
              ),
              border: Border(
                left: BorderSide(
                  color: AppColors.bleuArdoise,
                  width: AppDimensions.calendarBandAccent,
                ),
              ),
            ),
          );
    final internal = compact
        ? const SizedBox(
            width: width,
            child: CalendarDashedBar(color: AppColors.bleuArdoise),
          )
        : Container(
            width: width,
            height: AppDimensions.calendarKeySwatchHeight,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(
                Radius.circular(AppDimensions.calendarLegendSwatchRadius),
              ),
              border: Border.all(
                color: AppColors.bleuArdoise,
                width: AppDimensions.calendarBandInternalStroke,
              ),
            ),
          );
    Widget item(Widget swatch, List<Widget> rest) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: AppSpacing.xs + AppSpacing.xs / 4),
        ...rest,
      ],
    );
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        item(national, [
          if (!compact) ...[
            const Icon(
              SchoolCalendarTones.nationalIcon,
              size: AppDimensions.calendarSourceIcon,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.xs / 2),
          ],
          Text(
            compact
                ? l10n.schoolCalendarKeyNationalSolid
                : l10n.schoolCalendarKeyNational,
            style: style,
          ),
        ]),
        item(internal, [
          Text(
            compact
                ? l10n.schoolCalendarKeyInternalDashed
                : l10n.schoolCalendarKeyInternal,
            style: style,
          ),
        ]),
      ],
    );
  }
}
