import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/helpers/json_fields.dart';

/// Les éléments variables d'un agent, tels qu'ils descendent avec la paie.
class PayrollVariablesDto {
  final String staffMemberId;
  final int? overtimeMinutes;
  final int? overtimeRateInCents;
  final int? dependentChildren;
  final int? childcareInCents;
  final int? fixedPayoutInCents;
  final String? fixedPayoutReason;
  final String clientUpdatedAt;

  const PayrollVariablesDto({
    required this.staffMemberId,
    required this.clientUpdatedAt,
    this.overtimeMinutes,
    this.overtimeRateInCents,
    this.dependentChildren,
    this.childcareInCents,
    this.fixedPayoutInCents,
    this.fixedPayoutReason,
  });

  static PayrollVariablesDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw.text('staffMemberId');
    final at = raw.instant('clientUpdatedAt');
    if (id == null || at == null) return null;
    return PayrollVariablesDto(
      staffMemberId: id,
      clientUpdatedAt: at,
      overtimeMinutes: raw.integer('overtimeMinutes'),
      overtimeRateInCents: raw.integer('overtimeRateInCents'),
      dependentChildren: raw.integer('dependentChildren'),
      childcareInCents: raw.integer('childcareInCents'),
      fixedPayoutInCents: raw.integer('fixedPayoutInCents'),
      fixedPayoutReason: raw.text('fixedPayoutReason'),
    );
  }
}

/// Le taux de versement du mois, tel qu'il descend avec la paie (v2).
class PayrollPayoutPolicyDto {
  final int ratePercent;
  final String? reason;
  final String clientUpdatedAt;

  const PayrollPayoutPolicyDto({
    required this.ratePercent,
    required this.clientUpdatedAt,
    this.reason,
  });

  /// Lu à plat sur la paie (`payoutPercent`, `payoutReason`,
  /// `payoutClientUpdatedAt`). `null` hors bornes — un taux qu'on ne sait
  /// pas lire ne s'applique pas — et pour le 100 % jamais posé.
  static PayrollPayoutPolicyDto? tryParse(Map<dynamic, dynamic> payroll) {
    final rate = payroll.integer('payoutPercent');
    final at = payroll.instant('payoutClientUpdatedAt');
    if (rate == null || rate < 0 || rate > 100) return null;
    if (at == null && rate == 100) return null;
    return PayrollPayoutPolicyDto(
      ratePercent: rate,
      // Sans horloge, le taux du serveur cède à toute saisie locale.
      clientUpdatedAt: at ?? _epoch,
      reason: payroll.text('payoutReason'),
    );
  }

  static const String _epoch = '1970-01-01T00:00:00.000Z';
}

/// Un geste du circuit, tel que le serveur l'a enregistré.
class PayrollGestureDto {
  final String gestureId;
  final String kind;
  final String? reason;
  final String? by;
  final String at;

  const PayrollGestureDto({
    required this.gestureId,
    required this.kind,
    required this.at,
    this.reason,
    this.by,
  });

  static PayrollGestureDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw.text('gestureId');
    final kind = raw.text('kind');
    final at = raw.instant('at');
    if (id == null || kind == null || at == null) return null;
    return PayrollGestureDto(
      gestureId: id,
      kind: kind,
      at: at,
      reason: raw.text('reason'),
      by: raw.text('by'),
    );
  }
}

/// Une paie mensuelle telle que le flux `hr.payrolls` (ou l'accusé d'un
/// geste) la donne. Les lignes figées ne sont là qu'en `VALIDATED`, gardées
/// brutes : elles se relisent à la lecture.
class PayrollDto {
  final String id;
  final String month;
  final String status;
  final String? submittedAt;
  final String? submittedBy;
  final String? validatedAt;
  final String? validatedBy;
  final String? returnReason;
  final String? validationGestureId;
  final List<PayrollVariablesDto> variables;
  final List<PayrollGestureDto> gestures;

  /// `null` : 100 % jamais réglé, ou une paie v1.
  final PayrollPayoutPolicyDto? payoutPolicy;

  /// Liste vide hors `VALIDATED` ; `null` si le champ manque (ne rien
  /// effacer d'une paie validée).
  final List<Map<dynamic, dynamic>>? lines;
  final String? serverUpdatedAt;

  const PayrollDto({
    required this.id,
    required this.month,
    required this.status,
    this.submittedAt,
    this.submittedBy,
    this.validatedAt,
    this.validatedBy,
    this.returnReason,
    this.validationGestureId,
    this.variables = const [],
    this.gestures = const [],
    this.payoutPolicy,
    this.lines,
    this.serverUpdatedAt,
  });

  static PayrollDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final inner = raw['payroll'];
    if (inner is Map) return tryParse(inner);
    final id = raw.text('id');
    final month = raw.yearMonth('month');
    final status = raw.text('status');
    if (id == null || month == null || status == null) return null;
    final variables = raw['variables'];
    final gestures = raw['gestures'];
    final lines = raw['lines'];
    return PayrollDto(
      id: id,
      month: month,
      status: status,
      submittedAt: raw.instant('submittedAt'),
      submittedBy: raw.text('submittedBy'),
      validatedAt: raw.instant('validatedAt'),
      validatedBy: raw.text('validatedBy'),
      returnReason: raw.text('returnReason'),
      validationGestureId: raw.text('validationGestureId'),
      variables: [
        if (variables is List)
          for (final item in variables) ?PayrollVariablesDto.tryParse(item),
      ],
      gestures: [
        if (gestures is List)
          for (final item in gestures) ?PayrollGestureDto.tryParse(item),
      ],
      payoutPolicy: PayrollPayoutPolicyDto.tryParse(raw),
      lines: lines is List
          ? [
              for (final l in lines)
                if (l is Map) l,
            ]
          : null,
      serverUpdatedAt: raw.instant('serverUpdatedAt'),
    );
  }

  /// L'accusé d'un geste. Illisible = exception : l'écriture a eu lieu, mais
  /// la tablette ne sait pas en quoi.
  factory PayrollDto.fromJson(Map<String, dynamic> json) =>
      tryParse(json) ?? (throw const FormatException('Paie illisible'));
}

class PayrollPageDto extends ParsedKeysetPage<PayrollDto> {
  PayrollPageDto._(ParsedKeysetPage<PayrollDto> parsed)
    : super(items: parsed.items, page: parsed.page, skipped: parsed.skipped);

  factory PayrollPageDto.fromJson(Map<String, dynamic> json) =>
      PayrollPageDto._(ParsedKeysetPage.fromJson(json, PayrollDto.tryParse));
}
