import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/core/staff/local/payroll_settings_seed.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_fingerprint_json.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_fingerprint.dart';
import 'package:school_app_flutter/core/helpers/json_fields.dart';

// Les remontées de la paie qui ne sont pas des faits : réglages, éléments
// variables, gestes du circuit. Chacune telle qu'elle est mise en file.

/// `PUT /sync/payroll-settings` — `{ settings, authorId }`, dernier écrit gagne.
class PayrollSettingsRequestDto {
  final PayrollSettingsSeed settings;
  final String clientUpdatedAt;
  final String authorId;

  const PayrollSettingsRequestDto({
    required this.settings,
    required this.clientUpdatedAt,
    required this.authorId,
  });

  Map<String, dynamic> toJson() => {
    'settings': {...settings.toJson(), 'clientUpdatedAt': clientUpdatedAt},
    kOutboxAuthorIdKey: authorId,
  };

  static PayrollSettingsRequestDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final inner = raw['settings'];
    final settings = PayrollSettingsSeed.tryParse(inner);
    final at = inner is Map ? inner.instant('clientUpdatedAt') : null;
    final author = raw.text(kOutboxAuthorIdKey);
    if (settings == null || at == null || author == null) return null;
    return PayrollSettingsRequestDto(
      settings: settings,
      clientUpdatedAt: at,
      authorId: author,
    );
  }
}

/// `POST /sync/payroll-variables` — les éléments variables d'un agent pour
/// un mois, dernier écrit gagne.
class PayrollVariablesRequestDto {
  final String month;
  final String staffMemberId;
  final int? overtimeMinutes;
  final int? overtimeRateInCents;
  final int? dependentChildren;
  final String clientUpdatedAt;
  final String authorId;

  const PayrollVariablesRequestDto({
    required this.month,
    required this.staffMemberId,
    required this.clientUpdatedAt,
    required this.authorId,
    this.overtimeMinutes,
    this.overtimeRateInCents,
    this.dependentChildren,
  });

  Map<String, dynamic> toJson() => {
    'variables': {
      'month': month,
      'staffMemberId': staffMemberId,
      'overtimeMinutes': overtimeMinutes,
      'overtimeRateInCents': overtimeRateInCents,
      'dependentChildren': dependentChildren,
      'clientUpdatedAt': clientUpdatedAt,
    },
    kOutboxAuthorIdKey: authorId,
  };

  static PayrollVariablesRequestDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final inner = raw['variables'];
    if (inner is! Map) return null;
    final month = inner.yearMonth('month');
    final member = inner.text('staffMemberId');
    final at = inner.instant('clientUpdatedAt');
    final author = raw.text(kOutboxAuthorIdKey);
    if (month == null || member == null || at == null || author == null) {
      return null;
    }
    return PayrollVariablesRequestDto(
      month: month,
      staffMemberId: member,
      clientUpdatedAt: at,
      authorId: author,
      overtimeMinutes: inner.integer('overtimeMinutes'),
      overtimeRateInCents: inner.integer('overtimeRateInCents'),
      dependentChildren: inner.integer('dependentChildren'),
    );
  }
}

/// `POST /sync/payroll-gestures` — un geste du circuit, idempotent par son
/// `gestureId`. `expected` porte l'empreinte de ce qui a été vu.
class PayrollGestureRequestDto {
  final String gestureId;
  final String month;
  final String kind;
  final String? reason;
  final PayrollFingerprint? expected;
  final String clientRecordedAt;
  final String authorId;

  const PayrollGestureRequestDto({
    required this.gestureId,
    required this.month,
    required this.kind,
    required this.clientRecordedAt,
    required this.authorId,
    this.reason,
    this.expected,
  });

  Map<String, dynamic> toJson() => {
    'gesture': {
      'gestureId': gestureId,
      'month': month,
      'kind': kind,
      'reason': reason,
      'expected': expected == null
          ? null
          : PayrollFingerprintJson.encode(expected!),
      'clientRecordedAt': clientRecordedAt,
    },
    kOutboxAuthorIdKey: authorId,
  };

  static PayrollGestureRequestDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final inner = raw['gesture'];
    if (inner is! Map) return null;
    final id = inner.text('gestureId');
    final month = inner.yearMonth('month');
    final kind = inner.text('kind');
    final at = inner.instant('clientRecordedAt');
    final author = raw.text(kOutboxAuthorIdKey);
    if (id == null ||
        month == null ||
        kind == null ||
        at == null ||
        author == null) {
      return null;
    }
    return PayrollGestureRequestDto(
      gestureId: id,
      month: month,
      kind: kind,
      reason: inner.text('reason'),
      expected: PayrollFingerprintJson.tryParse(inner['expected']),
      clientRecordedAt: at,
      authorId: author,
    );
  }
}
