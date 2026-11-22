import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La traçabilité d'un emploi du temps (EDT-D3), à l'heure de l'école :
/// « Publié le 2 mars 2026 · 09:14 par Mme Mavinga (CP) » ; en brouillon,
/// « La version publiée reste en vigueur jusqu'à la publication · modifié
/// hier · 16:40 » ou « Jamais publié · modifié … ».
class TimetableTrace {
  const TimetableTrace._();

  /// La ligne sous l'identité, ou `null` quand il n'y a rien de vrai à dire
  /// (une version publiée dont la date n'est pas connue de l'appareil : on ne
  /// dit pas « Jamais publié » d'une classe publiée).
  static String? of(
    BuildContext context,
    ClassTimetableHeader? header, {
    required bool draft,
    DateTime? now,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final published = header?.isPublished ?? false;
    if (draft) {
      final at = header?.draftUpdatedAt;
      if (at == null) {
        return published
            ? l10n.classTimetableDraftOpen
            : l10n.classTimetableNeverPublished;
      }
      final when = _when(context, at, now ?? DateTime.now());
      return published
          ? l10n.classTimetableDraftTraceKept(when)
          : l10n.classTimetableDraftTraceNew(when);
    }
    if (!published) return l10n.classTimetableNeverPublished;
    final at = header?.publishedAt;
    if (at == null) return null;
    final by = header?.publishedBy;
    final role = by?.role?.trim();
    final name = [
      by?.name?.trim() ?? '—',
      if (role != null && role.isNotEmpty) '($role)',
    ].join(' ');
    return l10n.classTimetablePublishedOn(_stamp(context, at), name);
  }

  /// « 2 mars 2026 · 09:14 », à l'heure de l'école.
  static String _stamp(BuildContext context, DateTime instant) {
    final wall = SchoolTime.wallClock(instant);
    return '${_date(context, wall)} · ${_time(context, wall)}';
  }

  /// « à l'instant », « aujourd'hui · 16:40 », « hier · 16:40 », « le 2 mars
  /// 2026 · 16:40 ».
  static String _when(BuildContext context, DateTime at, DateTime now) {
    final l10n = AppLocalizations.of(context)!;
    final wall = SchoolTime.wallClock(at);
    final today = SchoolTime.wallClock(now);
    if (today.difference(wall).inMinutes.abs() < 1) {
      return l10n.classTimetableWhenJustNow;
    }
    final time = _time(context, wall);
    final days = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(wall.year, wall.month, wall.day)).inDays;
    return switch (days) {
      0 => l10n.classTimetableWhenToday(time),
      1 => l10n.classTimetableWhenYesterday(time),
      _ => l10n.classTimetableWhenOn(_date(context, wall), time),
    };
  }

  static String _date(BuildContext context, DateTime wall) =>
      '${wall.day} ${MaterialLocalizations.of(context).formatMonthYear(wall)}';

  static String _time(BuildContext context, DateTime wall) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay(hour: wall.hour, minute: wall.minute),
        alwaysUse24HourFormat: true,
      );
}
