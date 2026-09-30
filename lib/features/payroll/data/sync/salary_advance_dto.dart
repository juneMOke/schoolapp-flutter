import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_json.dart';

/// Une avance sur salaire, sur le fil : la même forme pour la remontée
/// (`{ advance, authorId }`) et la descente (plus ce que le serveur a figé).
class SalaryAdvanceDto {
  final String id;
  final String staffMemberId;
  final int amountInCents;
  final String currency;
  final int installments;
  final String firstMonth;
  final String reason;
  final String? reasonDetail;
  final String mode;
  final String grantedOn;
  final String clientRecordedAt;

  /// Descente seulement.
  final int? deductedInCents;
  final int? balanceInCents;
  final String? cancelledAt;
  final String? cancellationReason;
  final String? serverUpdatedAt;

  const SalaryAdvanceDto({
    required this.id,
    required this.staffMemberId,
    required this.amountInCents,
    required this.currency,
    required this.installments,
    required this.firstMonth,
    required this.reason,
    required this.mode,
    required this.grantedOn,
    required this.clientRecordedAt,
    this.reasonDetail,
    this.deductedInCents,
    this.balanceInCents,
    this.cancelledAt,
    this.cancellationReason,
    this.serverUpdatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'staffMemberId': staffMemberId,
    'amountInCents': amountInCents,
    'currency': currency,
    'installments': installments,
    'firstMonth': firstMonth,
    'reason': reason,
    'reasonDetail': reasonDetail,
    'mode': mode,
    'grantedOn': grantedOn,
    'clientRecordedAt': clientRecordedAt,
  };

  static SalaryAdvanceDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final inner = raw['advance'];
    if (inner is Map) return tryParse(inner);
    final id = raw.text('id');
    final member = raw.text('staffMemberId');
    final amount = raw.integer('amountInCents');
    final currency = raw.text('currency');
    final installments = raw.integer('installments');
    final firstMonth = raw.yearMonth('firstMonth');
    final reason = raw.text('reason');
    final mode = raw.text('mode');
    final grantedOn = raw.day('grantedOn');
    if (id == null ||
        member == null ||
        amount == null ||
        currency == null ||
        installments == null ||
        firstMonth == null ||
        reason == null ||
        mode == null ||
        grantedOn == null) {
      return null;
    }
    return SalaryAdvanceDto(
      id: id,
      staffMemberId: member,
      amountInCents: amount,
      currency: currency,
      installments: installments,
      firstMonth: firstMonth,
      reason: reason,
      reasonDetail: raw.text('reasonDetail'),
      mode: mode,
      grantedOn: grantedOn,
      clientRecordedAt:
          raw.instant('clientRecordedAt') ??
          raw.instant('recordedAt') ??
          '${grantedOn}T00:00:00.000Z',
      deductedInCents: raw.integer('deductedInCents'),
      balanceInCents: raw.integer('balanceInCents'),
      cancelledAt: raw.instant('cancelledAt'),
      cancellationReason: raw.text('cancellationReason'),
      serverUpdatedAt: raw.instant('serverUpdatedAt'),
    );
  }
}

/// `{ advance, authorId }`, tel que mis en file.
class SalaryAdvanceRequestDto {
  final SalaryAdvanceDto advance;
  final String authorId;

  const SalaryAdvanceRequestDto({
    required this.advance,
    required this.authorId,
  });

  Map<String, dynamic> toJson() => {
    'advance': advance.toJson(),
    kOutboxAuthorIdKey: authorId,
  };

  static SalaryAdvanceRequestDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final advance = SalaryAdvanceDto.tryParse(raw['advance']);
    final author = raw.text(kOutboxAuthorIdKey);
    if (advance == null || author == null) return null;
    return SalaryAdvanceRequestDto(advance: advance, authorId: author);
  }
}

class SalaryAdvancePageDto extends ParsedKeysetPage<SalaryAdvanceDto> {
  SalaryAdvancePageDto._(ParsedKeysetPage<SalaryAdvanceDto> parsed)
    : super(items: parsed.items, page: parsed.page, skipped: parsed.skipped);

  factory SalaryAdvancePageDto.fromJson(Map<String, dynamic> json) =>
      SalaryAdvancePageDto._(
        ParsedKeysetPage.fromJson(json, SalaryAdvanceDto.tryParse),
      );
}
