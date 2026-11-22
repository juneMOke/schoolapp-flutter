import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/school_calendar_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// La pastille de date (🆕, spec Calendrier §4.6) : le jour et le mois abrégé,
/// dans la teinte de la nature — pleine quand l'élément est en cours ou proche,
/// douce sinon.
///
/// Pourquoi neuf : `EteeloIconMedallion` porte une icône, pas une date.
class CalendarDateChip extends StatelessWidget {
  final DateTime date;
  final CalendarNatureTone tone;
  final bool strong;
  final double size;

  const CalendarDateChip({
    super.key,
    required this.date,
    required this.tone,
    this.strong = false,
    this.size = AppDimensions.calendarDateChipMedium,
  });

  @override
  Widget build(BuildContext context) {
    final month = MaterialLocalizations.of(
      context,
    ).formatShortMonthDay(date).replaceAll(RegExp(r'\d'), '').trim();
    final ink = strong ? AppColors.textOnDark : tone.ink;
    // Maquette `CalDateChip` : un peu plus haute que large, bord doux de la
    // teinte quand elle n'est pas pleine, mois en capitales.
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size + AppSpacing.xs,
        decoration: BoxDecoration(
          color: strong ? tone.tone : tone.soft,
          borderRadius: AppRadius.brMd,
          border: strong
              ? null
              : Border.all(
                  color: tone.tone.withValues(
                    alpha: AppDimensions.calendarToneBorderOpacity,
                  ),
                ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${date.day}',
                style: AppTypography.titleSmall.copyWith(color: ink, height: 1),
              ),
              const SizedBox(height: AppSpacing.xs / 2),
              Text(
                month.replaceAll('.', '').toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: ink,
                  height: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
