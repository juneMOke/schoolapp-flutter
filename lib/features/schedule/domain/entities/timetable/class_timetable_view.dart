import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_grid.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';

/// Une classe proposée par le choix Cycle → Niveau → Classe (EDT §4.6 A).
class TimetableClassOption extends Equatable {
  final String classroomId;
  final String name;
  final String cycleCode;
  final String cycleName;
  final String levelCode;
  final String levelName;
  final String? room;

  const TimetableClassOption({
    required this.classroomId,
    required this.name,
    required this.cycleCode,
    required this.cycleName,
    required this.levelCode,
    required this.levelName,
    this.room,
  });

  @override
  List<Object?> get props => [classroomId, name, cycleCode, levelCode, room];
}

/// Tout ce que l'écran montre d'une classe, lu en local.
class ClassTimetableView extends Equatable {
  final TimetableClassOption classroom;
  final TimeGrid? grid;

  /// Les créneaux de la grille de la classe, rangés par heure.
  final List<TimeSlot> slots;
  final ClassTimetableHeader? header;
  final List<ClassTimetableCell> published;
  final List<ClassTimetableCell> draft;
  final List<TimetableCourse> programme;

  /// `schedule.timetable-cells` n'a jamais été tiré sur l'appareil : le
  /// contrôle des conflits est indisponible (EDT §5, « partiel »).
  final bool othersKnown;

  /// Les séances qui occupent les enseignants ailleurs (publiées et
  /// brouillons des autres classes) : les conflits sur l'appareil (R4, A11).
  final List<TeacherBooking> bookings;

  /// Des gestes de cette classe attendent leur envoi : « Publier » attend.
  final bool hasPending;

  /// Des gestes refusés parce que leur brouillon a été clos entre-temps.
  final List<ClassTimetableCell> ended;

  /// Des cases écrasées par un autre appareil, pas encore annoncées.
  final int superseded;

  const ClassTimetableView({
    required this.classroom,
    required this.grid,
    required this.slots,
    required this.header,
    required this.published,
    required this.draft,
    required this.programme,
    required this.othersKnown,
    this.bookings = const [],
    this.hasPending = false,
    this.ended = const [],
    this.superseded = 0,
  });

  bool get hasDraft => header?.draftId != null;

  /// Les domaines de la classe, dans l'ordre de la grille de notes (bulletin).
  List<String> get domainOrder {
    final sorted = [...programme]
      ..sort(
        (a, b) =>
            (a.domainOrder ?? 1 << 30).compareTo(b.domainOrder ?? 1 << 30),
      );
    final ids = <String>[];
    for (final c in sorted) {
      final id = c.domainId;
      if (id != null && !ids.contains(id)) ids.add(id);
    }
    return ids;
  }

  @override
  List<Object?> get props => [
    classroom,
    grid,
    slots,
    header,
    published,
    draft,
    programme,
    othersKnown,
    bookings,
    hasPending,
    ended,
    superseded,
  ];
}
