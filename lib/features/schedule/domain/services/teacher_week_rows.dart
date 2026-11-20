import 'package:school_app_flutter/features/schedule/domain/entities/time_grid.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';

/// Un créneau tel que la tablette le connaît, avec sa grille.
class GridTimeSlot {
  final TimeSlot slot;
  final String? timeGridId;

  const GridTimeSlot(this.slot, this.timeGridId);
}

/// Les rangées de la semaine d'un enseignant, rangées **par heure** (EDT-1) :
/// un professeur du primaire et du secondaire a des créneaux de deux grilles,
/// et l'ordre d'un créneau dans sa grille ne dit plus rien de l'heure.
///
/// - Seuls les créneaux des grilles où il a cours sont montrés ; sans séance
///   (ou avant EDT-1, grilles inconnues), tous les créneaux.
/// - La récréation de chaque grille montrée devient une rangée-bande, sauf si
///   un créneau de la grille l'occupe déjà (ancienne récréation-créneau).
/// - Ordre : début, puis fin, puis grille, puis ordre dans la grille.
class TeacherWeekRows {
  const TeacherWeekRows._();

  static List<TimeSlot> compose({
    required List<GridTimeSlot> slots,
    required Set<String> usedSlotIds,
    required Map<String, TimeGrid> grids,
  }) {
    final usedGrids = {
      for (final s in slots)
        if (usedSlotIds.contains(s.slot.id) && s.timeGridId != null)
          s.timeGridId!,
    };
    final shown = usedGrids.isEmpty
        ? slots
        : [
            for (final s in slots)
              if (s.timeGridId == null || usedGrids.contains(s.timeGridId)) s,
          ];
    final rows = <(int, int, String, int, TimeSlot)>[];
    for (final s in shown) {
      final range = MinuteRange.fromClocks(s.slot.startTime, s.slot.endTime);
      rows.add((
        range?.startMinute ?? 0,
        range?.endMinute ?? 0,
        s.timeGridId ?? '',
        s.slot.order,
        s.slot,
      ));
    }
    for (final gridId in usedGrids) {
      final grid = grids[gridId];
      final recess = grid?.recess;
      if (grid == null || recess == null) continue;
      final occupied = shown.any((s) {
        if (s.timeGridId != gridId) return false;
        final range = MinuteRange.fromClocks(s.slot.startTime, s.slot.endTime);
        return range != null && SlotOverlap.overlaps(range, recess);
      });
      if (occupied) continue;
      rows.add((
        recess.startMinute,
        recess.endMinute,
        gridId,
        -1,
        TimeSlot(
          id: 'recess:$gridId',
          order: -1,
          startTime: _clock(recess.startMinute),
          endTime: _clock(recess.endMinute),
          label: usedGrids.length > 1 ? grid.name : null,
          isBreak: true,
        ),
      ));
    }
    rows.sort((a, b) {
      for (final c in [
        a.$1.compareTo(b.$1),
        a.$2.compareTo(b.$2),
        a.$3.compareTo(b.$3),
        a.$4.compareTo(b.$4),
      ]) {
        if (c != 0) return c;
      }
      return 0;
    });
    return [for (final r in rows) r.$5];
  }

  static String _clock(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}:00';
}
