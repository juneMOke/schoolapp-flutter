import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

/// Ce que devient une séance dans la grille (EDT §4.6 D).
enum SessionEmphasis {
  normal,

  /// Son cours est repéré (survol ou focus, ici ou dans la répartition).
  linked,

  /// Un autre cours est repéré, ou son domaine est filtré.
  dimmed,
}

/// Un jour sans cours de la semaine datée (férié, vacances) : l'en-tête de
/// sa colonne et la période, nommée au premier créneau.
class ScheduleClosedDay {
  final String header;
  final String period;

  const ScheduleClosedDay({required this.header, required this.period});
}

/// Les marques posées sur la grille et la journée, au-delà des séances :
/// jours fermés, alertes (conflit, hors programme, refus), séance en cours,
/// cours repéré, filtre de domaine. Vide par défaut : la vue enseignant n'en
/// pose aucune.
class ScheduleGridMarks {
  final Map<Weekday, ScheduleClosedDay> closedDays;

  /// Séance (id) → raison affichée (« Conflit avec 7e B », « Hors programme »).
  final Map<String, String> alerts;

  /// La séance du créneau actuel, cette semaine (R11).
  final String? currentSessionId;

  /// Le cours repéré (I5) : ses séances reliées, les autres estompées.
  final String? linkedCoursId;

  /// Le filtre de domaine (I6) : les cours montrés ; `null` : tous.
  final Set<String>? visibleCoursIds;

  /// Survol ou focus d'une séance : son cours, `null` en sortant.
  final ValueChanged<String?>? onHoverCours;

  const ScheduleGridMarks({
    this.closedDays = const {},
    this.alerts = const {},
    this.currentSessionId,
    this.linkedCoursId,
    this.visibleCoursIds,
    this.onHoverCours,
  });

  static const none = ScheduleGridMarks();

  SessionEmphasis emphasisOf(TimetableCell cell) {
    final visible = visibleCoursIds;
    if (visible != null && !visible.contains(cell.coursId)) {
      return SessionEmphasis.dimmed;
    }
    final linked = linkedCoursId;
    if (linked == null) return SessionEmphasis.normal;
    return cell.coursId == linked
        ? SessionEmphasis.linked
        : SessionEmphasis.dimmed;
  }
}

/// Ce qu'on glisse dans un brouillon (I9 à I11) : un cours de la réserve, ou
/// une séance déjà posée.
sealed class TimetableDragData {
  const TimetableDragData();
}

final class CourseDragData extends TimetableDragData {
  final String coursId;

  const CourseDragData(this.coursId);
}

final class SessionDragData extends TimetableDragData {
  final TimetableCell cell;
  final Weekday day;
  final TimeSlot slot;

  const SessionDragData(this.cell, this.day, this.slot);
}

/// Le glisser-déposer d'un brouillon, à partir de 976 dp reçus (R14) : au
/// doigt après un appui long ([longPress]), à la souris tout de suite.
class ScheduleGridDrag {
  final bool longPress;

  /// Le dépôt est-il permis ici ? Un dépôt refusé ne s'allume pas.
  final bool Function(TimetableDragData data, Weekday day, TimeSlot slot)
  canDrop;

  final void Function(TimetableDragData data, Weekday day, TimeSlot slot)
  onDrop;

  const ScheduleGridDrag({
    required this.longPress,
    required this.canDrop,
    required this.onDrop,
  });
}

/// Un jour fermé se dessine hachuré (EDT §4.6 « jour fermé »).
class HatchPainter extends CustomPainter {
  final Color color;
  final double gap;
  final double stroke;

  const HatchPainter({
    required this.color,
    required this.gap,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke;
    for (var x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(HatchPainter old) =>
      old.color != color || old.gap != gap || old.stroke != stroke;
}
