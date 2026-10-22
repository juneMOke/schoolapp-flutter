import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/justification/attendance_justification_dto.dart';

/// Une page keyset de justifications (`GET /sync/attendance-justifications`).
class AttendanceJustificationPageDto
    implements KeysetPageDto<AttendanceJustificationDto> {
  @override
  final List<AttendanceJustificationDto> items;
  @override
  final KeysetPageEnvelope page;

  const AttendanceJustificationPageDto({
    required this.items,
    required this.page,
  });

  factory AttendanceJustificationPageDto.fromJson(Map<String, dynamic> json) {
    final items = <AttendanceJustificationDto>[];
    for (final raw in (json['items'] as List<dynamic>? ?? const [])) {
      try {
        items.add(
          AttendanceJustificationDto.fromJson(raw as Map<String, dynamic>),
        );
      } catch (_) {
        // Une ligne illisible n'empêche pas la page de s'appliquer (sinon le
        // flux entier se figerait). Le curseur avance quand même : elle ne
        // redescendra qu'à sa prochaine modification côté serveur.
      }
    }
    return AttendanceJustificationPageDto(
      items: items,
      page: KeysetPageEnvelope.fromJson(json),
    );
  }
}
