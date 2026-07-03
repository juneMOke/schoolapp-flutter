import 'package:school_app_flutter/features/academics/presentation/helpers/academics_class_visual.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';

/// Entrée de légende : une classe présente dans la semaine, associée à sa
/// couleur déterministe (cf. [ScheduleClassPalette]).
class ScheduleLegendEntry {
  final String classroomId;
  final String classroomLabel;
  final AcademicsClassVisual visual;

  const ScheduleLegendEntry({
    required this.classroomId,
    required this.classroomLabel,
    required this.visual,
  });
}

/// Attribue à chaque **classe** de l'emploi du temps une teinte déterministe.
///
/// La spec assigne à chaque classe une couleur d'un jeu fixe ; on réutilise la
/// palette « Mes cours » ([AcademicsClassVisual]) en indexant chaque classe par
/// son **ordre d'apparition** dans la grille (lignes de créneaux × jours). Ainsi
/// la puce de séance, la rangée de la vue Jour et la légende partagent la même
/// couleur pour une classe donnée.
class ScheduleClassPalette {
  /// classroomId → rang d'apparition (0-based).
  final Map<String, int> _rankById;

  /// classroomId → libellé (pour la légende), dans l'ordre d'apparition.
  final Map<String, String> _labelById;

  const ScheduleClassPalette._(this._rankById, this._labelById);

  /// Construit la palette depuis la matrice chargée, en parcourant les cases
  /// occupées ligne par ligne, jour par jour (ordre stable et reproductible).
  factory ScheduleClassPalette.fromTimetable(WeeklyTimetable timetable) {
    final rankById = <String, int>{};
    final labelById = <String, String>{};

    for (final row in timetable.rows) {
      for (final day in timetable.days) {
        final cell = row.cellFor(day);
        if (cell == null) {
          continue;
        }
        rankById.putIfAbsent(cell.classroomId, () => rankById.length);
        labelById[cell.classroomId] = cell.classroomLabel;
      }
    }

    return ScheduleClassPalette._(rankById, labelById);
  }

  /// Teinte d'une classe. Repli sur le premier ton de la palette pour une
  /// classe inconnue (ne lève jamais).
  AcademicsClassVisual visualForClassroom(String classroomId) =>
      AcademicsClassVisual.forIndex(_rankById[classroomId] ?? 0);

  /// Classes présentes dans la semaine, dédupliquées, dans l'ordre d'apparition.
  List<ScheduleLegendEntry> get legendEntries => _labelById.entries
      .map(
        (entry) => ScheduleLegendEntry(
          classroomId: entry.key,
          classroomLabel: entry.value,
          visual: visualForClassroom(entry.key),
        ),
      )
      .toList(growable: false);
}
