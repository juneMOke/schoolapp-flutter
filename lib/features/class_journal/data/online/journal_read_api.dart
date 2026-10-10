import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/core/helpers/json_fields.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_entry_dto.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_read_line.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_teacher.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';

/// La lecture **en ligne** des journaux (la direction) : la journée d'un
/// professeur, la liste des enseignants. Écrite sur Dio et lue à la main,
/// comme la lecture en ligne du programme : une ligne illisible est écartée.
class JournalReadApi {
  final Dio _dio;

  const JournalReadApi(this._dio);

  Future<List<JournalReadLine>> dayOf(
    Map<String, dynamic> extras,
    String teacherId,
    DateTime date,
  ) async {
    final response = await _dio.get<Object?>(
      AppConstants.academicsJournalEndpoint,
      queryParameters: {
        'teacherId': teacherId,
        'date': DateOnlyJsonHelper.toJson(date),
      },
      options: Options(extra: extras),
    );
    final body = response.data;
    final raw = body is Map ? body['lignes'] : null;
    return [
      if (raw is List)
        for (final item in raw) ?_lineOf(item),
    ];
  }

  Future<List<JournalTeacher>> teachers(Map<String, dynamic> extras) async {
    final response = await _dio.get<Object?>(
      AppConstants.teachersEndpoint,
      options: Options(extra: extras),
    );
    final body = response.data;
    return [
      if (body is List)
        for (final item in body) ?_teacherOf(item),
    ];
  }

  static JournalReadLine? _lineOf(Object? raw) {
    if (raw is! Map) return null;
    final coursId = raw.text('coursId');
    final entry = JournalEntryDto.tryParse(raw['entry']);
    final slot = _slotOf(raw['creneau']);
    final timeSlotId = slot?.id ?? entry?.timeSlotId;
    if (coursId == null || timeSlotId == null) return null;
    return JournalReadLine(
      coursId: coursId,
      subjectLabel: raw.text('branche') ?? '',
      classroomLabel: raw.text('classroomLabel') ?? '',
      slot: slot,
      timeSlotId: timeSlotId,
      inTimetable: raw.flag('inTimetable') ?? true,
      entry: entry?.toEntity(),
    );
  }

  static TimeSlot? _slotOf(Object? raw) {
    if (raw is! Map) return null;
    final id = raw.text('id');
    final order = raw.integer('slotOrder');
    final start = raw.text('startTime');
    final end = raw.text('endTime');
    if (id == null || order == null || start == null || end == null) {
      return null;
    }
    return TimeSlot(
      id: id,
      order: order,
      startTime: start,
      endTime: end,
      label: raw.text('label'),
    );
  }

  /// « NOM Post-nom Prénom », l'ordre des listes de l'école.
  static JournalTeacher? _teacherOf(Object? raw) {
    if (raw is! Map) return null;
    final id = raw.text('id');
    if (id == null) return null;
    final name = [
      raw.text('lastName'),
      raw.text('middleName'),
      raw.text('firstName'),
    ].whereType<String>().join(' ');
    return JournalTeacher(id: id, displayName: name);
  }
}
