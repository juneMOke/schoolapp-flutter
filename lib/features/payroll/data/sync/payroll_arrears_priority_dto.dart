import 'package:school_app_flutter/core/helpers/json_fields.dart';
import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';

/// Le drapeau « priorité » d'un arriéré (T9) : un agent, son mois d'origine,
/// levé ou baissé. Sans effet sur les montants. Id = uuid5 de l'agent sur
/// `"arrears-priority:" + YYYY-MM`, le même sur toutes les tablettes.
class PayrollArrearsPriorityDto {
  final String id;
  final String staffMemberId;

  /// `YYYY-MM` — le mois d'origine de l'arriéré.
  final String month;
  final bool prioritized;
  final String clientUpdatedAt;

  const PayrollArrearsPriorityDto({
    required this.id,
    required this.staffMemberId,
    required this.month,
    required this.prioritized,
    required this.clientUpdatedAt,
  });

  static PayrollArrearsPriorityDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final inner = raw['priority'];
    if (inner is Map) return tryParse(inner);
    final id = raw.text('id');
    final member = raw.text('staffMemberId');
    final month = raw.yearMonth('month');
    final at = raw.instant('clientUpdatedAt');
    final prioritized = raw['prioritized'];
    if (id == null ||
        member == null ||
        month == null ||
        at == null ||
        prioritized is! bool) {
      return null;
    }
    return PayrollArrearsPriorityDto(
      id: id,
      staffMemberId: member,
      month: month,
      prioritized: prioritized,
      clientUpdatedAt: at,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'staffMemberId': staffMemberId,
    'month': month,
    'prioritized': prioritized,
    'clientUpdatedAt': clientUpdatedAt,
  };
}

class PayrollArrearsPriorityPageDto
    extends ParsedKeysetPage<PayrollArrearsPriorityDto> {
  PayrollArrearsPriorityPageDto._(
    ParsedKeysetPage<PayrollArrearsPriorityDto> parsed,
  ) : super(items: parsed.items, page: parsed.page, skipped: parsed.skipped);

  factory PayrollArrearsPriorityPageDto.fromJson(Map<String, dynamic> json) =>
      PayrollArrearsPriorityPageDto._(
        ParsedKeysetPage.fromJson(json, PayrollArrearsPriorityDto.tryParse),
      );
}

/// `POST /sync/payroll-arrears-priorities` — `{ priority, authorId }`,
/// dernier écrit gagne.
class PayrollArrearsPriorityRequestDto {
  final PayrollArrearsPriorityDto priority;
  final String authorId;

  const PayrollArrearsPriorityRequestDto({
    required this.priority,
    required this.authorId,
  });

  Map<String, dynamic> toJson() => {
    'priority': priority.toJson(),
    kOutboxAuthorIdKey: authorId,
  };

  static PayrollArrearsPriorityRequestDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final priority = PayrollArrearsPriorityDto.tryParse(raw['priority']);
    final author = raw.text(kOutboxAuthorIdKey);
    if (priority == null || author == null) return null;
    return PayrollArrearsPriorityRequestDto(
      priority: priority,
      authorId: author,
    );
  }
}
