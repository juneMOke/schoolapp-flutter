import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';

/// Un créneau de la grille, avec ses minutes.
class GridSlot extends Equatable {
  final String slotId;
  final int order;
  final MinuteRange range;

  const GridSlot({
    required this.slotId,
    required this.order,
    required this.range,
  });

  @override
  List<Object?> get props => [slotId, order, range];
}

/// Un cours du programme d'une classe : sa branche (l'UUID qui rend « le
/// Français de 7A » équivalent au « Français de 7C » — une branche est propre
/// à l'école, son code peut manquer) et son enseignant.
class ProgrammeCourse extends Equatable {
  final String coursId;
  final String branchId;
  final String? teacherId;

  const ProgrammeCourse({
    required this.coursId,
    required this.branchId,
    this.teacherId,
  });

  @override
  List<Object?> get props => [coursId, branchId, teacherId];
}

/// Une case pleine de la classe source, avec la branche de son cours.
class SourceCell extends Equatable {
  final Weekday day;
  final String slotId;
  final String coursId;
  final String branchId;

  const SourceCell({
    required this.day,
    required this.slotId,
    required this.coursId,
    required this.branchId,
  });

  @override
  List<Object?> get props => [day, slotId, coursId, branchId];
}

/// Une case d'emploi du temps : un cours ou rien.
class TimetableCellValue extends Equatable {
  final Weekday day;
  final String slotId;
  final String? coursId;
  final String? teacherId;

  const TimetableCellValue({
    required this.day,
    required this.slotId,
    this.coursId,
    this.teacherId,
  });

  bool get isEmpty => coursId == null;

  @override
  List<Object?> get props => [day, slotId, coursId, teacherId];
}

class TimetableCopyResult extends Equatable {
  /// Toutes les cases de la grille, pleines ou vides (A6 : 36 cases
  /// explicites pour une grille de 6 jours × 6 créneaux).
  final List<TimetableCellValue> cells;
  final int taken;
  final int conflicts;
  final int noEquivalent;

  const TimetableCopyResult({
    required this.cells,
    required this.taken,
    required this.conflicts,
    required this.noEquivalent,
  });

  @override
  List<Object?> get props => [cells, taken, conflicts, noEquivalent];
}

/// Copie d'un emploi du temps vers une classe de même grille (EDT-R8, A6).
///
/// Pour chaque case de la source dont le créneau est dans [slots] (les autres
/// sont ignorées, sans être comptées) : le cours de la cible de même branche —
/// le plus petit `coursId` s'il y en a plusieurs ; aucun = `noEquivalent`. Si
/// son enseignant est pris dans une autre classe le même jour sur des minutes
/// qui chevauchent celles du créneau = `conflicts`, case laissée vide ; sinon
/// la case est prise (`taken`).
///
/// [TimetableCopyResult.cells] nomme **toutes** les cases, du lundi au samedi
/// puis créneau par créneau dans l'ordre (`order`) : c'est le lot qui monte.
///
/// La même fonction sert l'aperçu (D12) et la copie. Elle ne tourne que sur
/// l'appareil (A18) ; sa référence est le script `generate-vectors.py` du back,
/// et `schedule/copy-vectors.json` la tient juste.
class TimetableCopy {
  const TimetableCopy._();

  static TimetableCopyResult compute({
    required String targetClassroomId,
    required List<GridSlot> slots,
    required List<SourceCell> sourceCells,
    required List<ProgrammeCourse> targetCourses,
    required Iterable<TeacherBooking> otherBookings,
  }) {
    final targetByBranch = <String, ProgrammeCourse>{};
    for (final course in targetCourses) {
      final known = targetByBranch[course.branchId];
      if (known == null || course.coursId.compareTo(known.coursId) < 0) {
        targetByBranch[course.branchId] = course;
      }
    }
    final sourceByCell = <(Weekday, String), SourceCell>{
      for (final cell in sourceCells) (cell.day, cell.slotId): cell,
    };
    final ordered = [...slots]..sort((a, b) => a.order.compareTo(b.order));
    var taken = 0;
    var conflicts = 0;
    var noEquivalent = 0;
    final cells = <TimetableCellValue>[];
    for (final day in Weekday.values) {
      for (final slot in ordered) {
        final source = sourceByCell[(day, slot.slotId)];
        final target = source == null ? null : targetByBranch[source.branchId];
        if (source != null && target == null) noEquivalent++;
        final blocked =
            target != null &&
            SlotOverlap.conflictsFor(
              teacherId: target.teacherId,
              classroomId: targetClassroomId,
              day: day,
              range: slot.range,
              bookings: otherBookings,
            ).isNotEmpty;
        if (blocked) conflicts++;
        final placed = target != null && !blocked;
        if (placed) taken++;
        cells.add(
          TimetableCellValue(
            day: day,
            slotId: slot.slotId,
            coursId: placed ? target.coursId : null,
            teacherId: placed ? target.teacherId : null,
          ),
        );
      }
    }
    return TimetableCopyResult(
      cells: cells,
      taken: taken,
      conflicts: conflicts,
      noEquivalent: noEquivalent,
    );
  }
}
