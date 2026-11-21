import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_sheet.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/session_detail_sheet.dart';

/// I4 — toucher une séance en consultation ouvre O1 (feuille du bas sous
/// 760, modale centrée au-delà), datée de la semaine affichée.
class SessionOpener {
  final ClassTimetableView view;
  final Map<Weekday, DateTime> dates;

  /// La séance du créneau actuel, cette semaine (R11).
  final String? currentId;

  const SessionOpener({
    required this.view,
    required this.dates,
    required this.currentId,
  });

  Future<void> open(BuildContext context, TimetableCell cell) async {
    final source = [
      for (final c in view.published)
        if (c.id == cell.sessionId) c,
    ].firstOrNull;
    if (source == null) return;
    await showEteeloAdaptiveSheet<void>(
      context: context,
      builder: (_) => SessionDetailSheet(
        view: view,
        cell: source,
        currentId: currentId,
        dates: dates,
      ),
    );
  }
}
