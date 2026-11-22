import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/school_calendar_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'œil d'une ligne (maquette `.cal-eye`) : rond blanc, icône et bord de la
/// teinte ; plein de la teinte quand la ligne est survolée.
class CalendarEye extends StatelessWidget {
  final CalendarNatureTone tone;
  final bool small;
  final bool highlighted;

  const CalendarEye({
    super.key,
    required this.tone,
    this.small = false,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small
        ? AppDimensions.calendarEyeSmall
        : AppDimensions.calendarEye;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: highlighted ? tone.tone : AppColors.surfaceRaised,
        border: Border.all(
          color: highlighted
              ? tone.tone
              : tone.tone.withValues(
                  alpha: AppDimensions.calendarToneBorderOpacity,
                ),
        ),
      ),
      child: Icon(
        Icons.visibility_outlined,
        size: small
            ? AppDimensions.calendarEyeIconSmall
            : AppDimensions.calendarEyeIcon,
        color: highlighted ? AppColors.textOnDark : tone.tone,
      ),
    );
  }
}

/// La nature d'un élément en pastille douce : icône et libellé.
class CalendarNatureTag extends StatelessWidget {
  final CalendarElement element;

  const CalendarNatureTag(this.element, {super.key});

  @override
  Widget build(BuildContext context) {
    final tone = element.nature.tone;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tone.icon,
            size: AppDimensions.calendarNatureTagIcon,
            color: tone.ink,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              CalendarLabels.nature(
                AppLocalizations.of(context)!,
                element.nature,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: tone.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La source en texte : « Cadre national » au cadenas, ou « Interne » au
/// crayon (maquette `CalSourceTag`).
class CalendarSourceTag extends StatelessWidget {
  final CalendarElement element;

  const CalendarSourceTag(this.element, {super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final national = element.isNational;
    final color = national ? AppColors.bleuProfond : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          national ? SchoolCalendarTones.nationalIcon : Icons.edit_outlined,
          size: AppDimensions.calendarSourceIcon,
          color: color,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            national
                ? l10n.schoolCalendarNationalFramework
                : l10n.schoolCalendarInternal,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Une pastille d'état d'une ligne : « En cours », « À vérifier ».
class CalendarRowPill extends StatelessWidget {
  final String label;
  final Color ink;
  final Color soft;
  final IconData? icon;

  const CalendarRowPill({
    super.key,
    required this.label,
    required this.ink,
    required this.soft,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs / 4,
    ),
    decoration: BoxDecoration(color: soft, borderRadius: AppRadius.brPill),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon case final icon?) ...[
          Icon(icon, size: AppDimensions.calendarSourceIcon, color: ink),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Le petit signe de la source dans la liste du mois : le cadenas, ou un
/// carré en tirets de la teinte.
class CalendarSourceMark extends StatelessWidget {
  final CalendarElement element;

  const CalendarSourceMark(this.element, {super.key});

  @override
  Widget build(BuildContext context) {
    if (element.isNational) {
      return const Icon(
        SchoolCalendarTones.nationalIcon,
        size: AppDimensions.calendarNatureTagIcon,
        color: AppColors.textMuted,
      );
    }
    return Container(
      width: AppDimensions.calendarSourceSquare,
      height: AppDimensions.calendarSourceSquare,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(AppDimensions.calendarSourceSquareRadius),
        ),
        border: Border.all(
          color: element.nature.tone.tone,
          width: AppDimensions.calendarBandInternalStroke,
        ),
      ),
    );
  }
}
