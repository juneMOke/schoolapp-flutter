import 'package:school_app_flutter/features/schedule/data/models/time_slot_model.dart';
import 'package:school_app_flutter/features/schedule/data/models/timetable_cell_model.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_row.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

/// Modèle du `TimetableRowDto`.
///
/// Parsing **manuel** (pas de `@JsonSerializable`) : `cells` est une map keyée
/// par jour dont les valeurs sont **nullables** (`null` = créneau libre), cas
/// que json_serializable gère mal. On garde les clés en `String` wire ici ;
/// [toEntity] les convertit en [Weekday]. Ce modèle est en lecture seule (pas
/// de `toJson`).
class TimetableRowModel {
  final TimeSlotModel timeSlot;

  /// Case par jour (clé wire `MON`..`SAT`), valeur nullable (`null` = libre).
  final Map<String, TimetableCellModel?> cells;

  const TimetableRowModel({required this.timeSlot, required this.cells});

  factory TimetableRowModel.fromJson(Map<String, dynamic> json) {
    final rawCells = (json['cells'] as Map<String, dynamic>? ?? const {});
    final cells = <String, TimetableCellModel?>{
      for (final e in rawCells.entries)
        e.key: e.value == null
            ? null
            : TimetableCellModel.fromJson(e.value as Map<String, dynamic>),
    };
    return TimetableRowModel(
      timeSlot: TimeSlotModel.fromJson(
        json['timeSlot'] as Map<String, dynamic>,
      ),
      cells: cells,
    );
  }

  TimetableRow toEntity() => TimetableRow(
    timeSlot: timeSlot.toEntity(),
    cells: {
      for (final e in cells.entries)
        WeekdayX.fromWire(e.key): e.value?.toEntity(),
    },
  );
}
