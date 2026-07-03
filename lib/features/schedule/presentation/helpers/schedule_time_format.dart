import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';

/// Utilitaires de présentation de l'emploi du temps : formatage des heures
/// pures (`HH:mm:ss` → `HH:mm`), durée d'un créneau, jour courant et compteurs
/// dérivés. Purement présentation — ne lèvent jamais (repli défensif).
class ScheduleTimeFormat {
  const ScheduleTimeFormat._();

  /// `HH:mm:ss` (ou `HH:mm`) → `HH:mm`. Repli : renvoie la valeur telle quelle
  /// si elle n'est pas parsable.
  static String hourMinute(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) {
      return raw;
    }
    final hh = parts[0].padLeft(2, '0');
    final mm = parts[1].padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Durée d'un créneau en minutes (`endTime - startTime`). Repli sur `0` si
  /// les heures ne sont pas parsables ou incohérentes (fin ≤ début).
  static int slotDurationMinutes(TimeSlot slot) {
    final start = _minutesOfDay(slot.startTime);
    final end = _minutesOfDay(slot.endTime);
    if (start == null || end == null || end <= start) {
      return 0;
    }
    return end - start;
  }

  /// Jour de la semaine courant projeté sur [Weekday] (LUN→SAM). Renvoie `null`
  /// le dimanche (hors grille) — aucune colonne n'est alors marquée « auj. ».
  static Weekday? todayWeekday({DateTime? reference}) {
    final weekday =
        (reference ?? DateTime.now()).weekday; // 1 = lundi … 7 = dim.
    if (weekday < DateTime.monday || weekday > DateTime.saturday) {
      return null;
    }
    return Weekday.values[weekday - 1];
  }

  /// Nombre de séances placées dans la semaine (cases occupées de la matrice).
  static int sessionCount(WeeklyTimetable timetable) {
    var count = 0;
    for (final row in timetable.rows) {
      for (final day in timetable.days) {
        if (row.cellFor(day) != null) {
          count++;
        }
      }
    }
    return count;
  }

  /// Heures de cours cumulées de la semaine (somme des durées de chaque case
  /// occupée), en heures décimales **arrondies au dixième** (spec §2 : « arrondi
  /// 0,1 »). Ex. 15 séances de 50 min → 12,5 ; 7 séances → 5,8.
  static double totalCourseHours(WeeklyTimetable timetable) {
    var minutes = 0;
    for (final row in timetable.rows) {
      for (final day in timetable.days) {
        if (row.cellFor(day) != null) {
          minutes += slotDurationMinutes(row.timeSlot);
        }
      }
    }
    // (minutes / 60) arrondi à 0,1 : minutes/60*10 = minutes/6, puis /10.
    return (minutes / 6).round() / 10;
  }

  static int? _minutesOfDay(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) {
      return null;
    }
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) {
      return null;
    }
    return hours * 60 + minutes;
  }
}
