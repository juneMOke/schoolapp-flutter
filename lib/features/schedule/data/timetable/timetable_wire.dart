import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';

/// Une ligne descendue, son horloge serveur et sa disparition.
class PulledTimetableRow<T> {
  final T value;
  final int? serverUpdatedAtMs;
  final bool deleted;

  const PulledTimetableRow(
    this.value,
    this.serverUpdatedAtMs, {
    this.deleted = false,
  });
}

/// Le fil de l'emploi du temps par classe (contrat figé avec le back le
/// 2026-11-19). Une ligne illisible lève : la page la saute et la compte.
class TimetableWire {
  const TimetableWire._();

  static String _req(Map j, String key) {
    final v = j[key];
    if (v is! String || v.isEmpty) throw FormatException('champ $key absent');
    return v;
  }

  static int? _int(Object? v) => v is num ? v.toInt() : null;

  static DateTime? _instant(Object? v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toUtc();

  static TimetableCourse course(Object? raw) {
    final j = raw as Map<String, dynamic>;
    return TimetableCourse(
      coursId: _req(j, 'coursId'),
      classroomId: _req(j, 'classroomId'),
      branchId: _req(j, 'branchId'),
      branchLabel: (j['branchLabel'] as String?) ?? '',
      domainId: j['domainId'] as String?,
      domainLabel: j['domainLabel'] as String?,
      domainOrder: _int(j['domainOrder']),
      teacherId: j['teacherId'] as String?,
      teacherLabel: j['teacherLabel'] as String?,
      weeklyHours: _int(j['weeklyHours']),
    );
  }

  static PulledTimetableRow<ClassTimetableHeader> header(Object? raw) {
    final j = raw as Map<String, dynamic>;
    return PulledTimetableRow(
      ClassTimetableHeader(
        id: _req(j, 'id'),
        classroomId: _req(j, 'classroomId'),
        academicYearId: (j['academicYearId'] as String?) ?? '',
        publishedVersion: _int(j['publishedVersion']),
        publishedAt: _instant(j['publishedAt']),
        publishedBy: TimetableActor.fromJson(j['publishedBy']),
        draftId: j['draftId'] as String?,
        draftUpdatedAt: _instant(j['draftUpdatedAt']),
        draftUpdatedBy: TimetableActor.fromJson(j['draftUpdatedBy']),
        revision: _int(j['revision']) ?? 0,
      ),
      EpochIsoHelper.tryToEpochMs(j['serverUpdatedAt']),
      deleted: j['deleted'] == true,
    );
  }

  static PulledTimetableRow<ClassTimetableCell> cell(Object? raw) {
    final j = raw as Map<String, dynamic>;
    final start = _int(j['startMinute']);
    final end = _int(j['endMinute']);
    if (start == null || end == null) throw const FormatException('minutes');
    return PulledTimetableRow(
      ClassTimetableCell(
        id: _req(j, 'id'),
        classroomId: _req(j, 'classroomId'),
        classroomLabel: (j['classroomLabel'] as String?) ?? '',
        status: TimetableCellStatus.fromWire(j['status'] as String?),
        draftId: j['draftId'] as String?,
        day: WeekdayX.fromWire(_req(j, 'day')),
        slotId: _req(j, 'slotId'),
        range: MinuteRange(start, end),
        coursId: j['coursId'] as String?,
        teacherId: j['teacherId'] as String?,
        subjectLabel: j['subjectLabel'] as String?,
        teacherLabel: j['teacherLabel'] as String?,
        clientUpdatedAtMs: EpochIsoHelper.tryToEpochMs(j['clientUpdatedAt']),
      ),
      EpochIsoHelper.tryToEpochMs(j['serverUpdatedAt']),
      deleted: j['deleted'] == true,
    );
  }
}
