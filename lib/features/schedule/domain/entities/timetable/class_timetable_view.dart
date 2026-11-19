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

  /// Le rythme des périodes du cycle et le code catalogue du niveau : ce qui
  /// rend un élément du calendrier pertinent pour la classe (A2).
  final String? periodType;
  final String? catalogLevelCode;

  const TimetableClassOption({
    required this.classroomId,
    required this.name,
    required this.cycleCode,
    required this.cycleName,
    required this.levelCode,
    required this.levelName,
    this.room,
    this.periodType,
    this.catalogLevelCode,
  });

  @override
  List<Object?> get props => [
    classroomId,
    name,
    cycleCode,
    levelCode,
    room,
    periodType,
    catalogLevelCode,
  ];
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
  /// Les domaines dans l'ordre de leur teinte (D10) : `domainOrder`
  /// croissant (sans ordre en dernier), puis l'identifiant du domaine — la
  /// même règle que la pièce imprimée par le serveur (EDT-10), pour qu'un
  /// domaine ait la même couleur à l'écran et sur le papier.
  List<String> get domainOrder {
    final orderOf = <String, int>{};
    for (final c in programme) {
      final id = c.domainId;
      if (id == null) continue;
      final order = c.domainOrder ?? 1 << 30;
      final known = orderOf[id];
      if (known == null || order < known) orderOf[id] = order;
    }
    return orderOf.keys.toList()..sort((a, b) {
      final byOrder = orderOf[a]!.compareTo(orderOf[b]!);
      return byOrder != 0 ? byOrder : a.compareTo(b);
    });
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
