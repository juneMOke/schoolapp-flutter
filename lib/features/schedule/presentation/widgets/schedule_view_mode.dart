import 'package:school_app_flutter/core/constants/app_breakpoints.dart';

/// Bascule locale de l'écran emploi du temps, indépendante de la machine à
/// états de chargement (spec §00/§01) : grille hebdomadaire ou vue Jour.
enum ScheduleViewMode { week, day }

/// Mode d'affichage **par défaut** selon la largeur disponible : `day` sur
/// téléphone / petit écran (la grille hebdomadaire 5 jours y est trop serrée),
/// `week` au-delà. Simple repli : dès que l'utilisateur bascule manuellement,
/// son choix prime (cf. `ScheduleView`).
ScheduleViewMode defaultScheduleViewMode(double width) =>
    width < AppBreakpoints.scheduleWeekDefaultMin
    ? ScheduleViewMode.day
    : ScheduleViewMode.week;
