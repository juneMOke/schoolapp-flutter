import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/school_calendar_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
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
    final ink = strong ? tone.soft : tone.ink;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: strong ? tone.tone : tone.soft,
          borderRadius: AppRadius.brSm,
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
              Text(
                month,
                style: AppTypography.labelSmall.copyWith(color: ink, height: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
