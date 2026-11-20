import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// La teinte d'une nature du calendrier : ton plein, fond doux, encre lisible
/// sur le fond doux, et icône.
@immutable
class CalendarNatureTone {
  final Color tone;
  final Color soft;
  final Color ink;
  final IconData icon;

  const CalendarNatureTone({
    required this.tone,
    required this.soft,
    required this.ink,
    required this.icon,
  });
}

/// Grammaire chromatique des **natures** du calendrier scolaire (CAL-R3).
///
/// ## Pourquoi ce fichier vit dans `core`
///
/// La même nature doit avoir la même couleur dans le calendrier, dans les
/// bandeaux de l'emploi du temps et dans le module Examens (CAL-R3, EDT §4.3).
/// Trois modules la lisent : c'est une grammaire, comme `ListingTones`, pas la
/// palette d'un module. `core` ne descendant jamais dans `features`, le
/// fichier ne connaît pas l'enum des natures : chaque nature a son accesseur,
/// et le module fait la correspondance.
///
/// ## Deux sources, deux traits (CAL-R4)
///
/// Un élément national est plein, avec un cadenas ; un élément de l'école a un
/// contour en tirets. Le trait se lit sur [nationalIcon] et [isDashed].
class SchoolCalendarTones {
  const SchoolCalendarTones._();

  static const period = CalendarNatureTone(
    tone: AppColors.bleuArdoise,
    soft: AppColors.bleuArdoiseSoft,
    ink: AppColors.bleuArdoise,
    icon: Icons.timeline_outlined,
  );

  /// L'or doux ne tient pas en texte sur son fond : encre assombrie.
  static const assessment = CalendarNatureTone(
    tone: AppColors.orDoux,
    soft: AppColors.calendarAssessmentSoft,
    ink: AppColors.ambreInk,
    icon: Icons.quiz_outlined,
  );

  static const exam = CalendarNatureTone(
    tone: AppColors.terreCuite,
    soft: AppColors.terreCuiteSoft,
    ink: AppColors.terreCuiteInk,
    icon: Icons.assignment_outlined,
  );

  static const holidayBreak = CalendarNatureTone(
    tone: AppColors.vertSavane,
    soft: AppColors.calendarBreakSoft,
    ink: AppColors.vertSavane,
    icon: Icons.event_busy_outlined,
  );

  static const publicHoliday = CalendarNatureTone(
    tone: AppColors.calendarHoliday,
    soft: AppColors.calendarHolidaySoft,
    ink: AppColors.calendarHoliday,
    icon: Icons.account_balance_outlined,
  );

  static const schoolLife = CalendarNatureTone(
    tone: AppColors.textSecondary,
    soft: AppColors.calendarSchoolLifeSoft,
    ink: AppColors.textSecondary,
    icon: Icons.groups_outlined,
  );

  /// Le cadenas d'un élément du cadre national.
  static const IconData nationalIcon = Icons.lock_outline;

  /// Un élément de l'école se trace en tirets ; un élément national, plein.
  static bool isDashed({required bool isNational}) => !isNational;
}
