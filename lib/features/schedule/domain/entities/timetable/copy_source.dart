import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';

/// Une classe dont on peut copier l'emploi du temps (EDT-R8, D11) : même
/// grille horaire, un emploi du temps publié ou en brouillon.
class CopySource extends Equatable {
  final TimetableClassOption classroom;
  final bool isDraft;
  final List<ClassTimetableCell> cells;

  /// La branche de chaque cours de la source (la clé de la copie).
  final Map<String, String> branchByCours;

  const CopySource({
    required this.classroom,
    required this.isDraft,
    required this.cells,
    required this.branchByCours,
  });

  int get sessionCount => cells.where((c) => !c.isEmpty).length;

  @override
  List<Object?> get props => [classroom, isDraft, cells, branchByCours];
}
