import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/helpers/json_fields.dart';

/// Le résumé d'un mois clos du Pointage (flux `hr.staff-attendance-summaries`,
/// sous `hr.pay.read`). Les agents restent bruts : ils se relisent à la
/// lecture.
class AttendanceSummaryDto {
  final String month;
  final String? closedAt;
  final List<Map<dynamic, dynamic>> agents;
  final String? serverUpdatedAt;

  const AttendanceSummaryDto({
    required this.month,
    required this.agents,
    this.closedAt,
    this.serverUpdatedAt,
  });

  static AttendanceSummaryDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final month = raw.yearMonth('month');
    final agents = raw['agents'];
    if (month == null || agents is! List) return null;
    return AttendanceSummaryDto(
      month: month,
      closedAt: raw.instant('closedAt'),
      agents: [
        for (final agent in agents)
          if (agent is Map && agent.text('staffMemberId') != null) agent,
      ],
      serverUpdatedAt: raw.instant('serverUpdatedAt'),
    );
  }
}

class AttendanceSummaryPageDto extends ParsedKeysetPage<AttendanceSummaryDto> {
  AttendanceSummaryPageDto._(ParsedKeysetPage<AttendanceSummaryDto> parsed)
    : super(items: parsed.items, page: parsed.page, skipped: parsed.skipped);

  factory AttendanceSummaryPageDto.fromJson(Map<String, dynamic> json) =>
      AttendanceSummaryPageDto._(
        ParsedKeysetPage.fromJson(json, AttendanceSummaryDto.tryParse),
      );
}
