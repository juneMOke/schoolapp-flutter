import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/core/helpers/json_fields.dart';

/// Un versement de salaire sur le fil — remontée (`{ disbursement, authorId }`)
/// et descente (plus l'annulation que le serveur a enregistrée).
class PayrollDisbursementDto {
  final String id;
  final String month;
  final String staffMemberId;
  final String validationGestureId;
  final int amountInCents;
  final String currency;
  final String mode;
  final String? operator;
  final String? payoutPhone;
  final String? reference;
  final String? bankName;
  final String? bankAccount;
  final bool signedRegister;
  final String paidAt;

  /// Descente seulement.
  final String? recordedBy;
  final String? cancelledAt;
  final String? cancellationReason;
  final String? serverUpdatedAt;

  const PayrollDisbursementDto({
    required this.id,
    required this.month,
    required this.staffMemberId,
    required this.validationGestureId,
    required this.amountInCents,
    required this.currency,
    required this.mode,
    required this.paidAt,
    this.operator,
    this.payoutPhone,
    this.reference,
    this.bankName,
    this.bankAccount,
    this.signedRegister = false,
    this.recordedBy,
    this.cancelledAt,
    this.cancellationReason,
    this.serverUpdatedAt,
  });

  /// Le même versement rattaché à une autre validation (régularisation N2).
  PayrollDisbursementDto underValidation(String gestureId) =>
      PayrollDisbursementDto(
        id: id,
        month: month,
        staffMemberId: staffMemberId,
        validationGestureId: gestureId,
        amountInCents: amountInCents,
        currency: currency,
        mode: mode,
        paidAt: paidAt,
        operator: operator,
        payoutPhone: payoutPhone,
        reference: reference,
        bankName: bankName,
        bankAccount: bankAccount,
        signedRegister: signedRegister,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'month': month,
    'staffMemberId': staffMemberId,
    'validationGestureId': validationGestureId,
    'amountInCents': amountInCents,
    'currency': currency,
    'mode': mode,
    'operator': operator,
    'payoutPhone': payoutPhone,
    'reference': reference,
    'bankName': bankName,
    'bankAccount': bankAccount,
    'signedRegister': signedRegister,
    'paidAt': paidAt,
  };

  static PayrollDisbursementDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final inner = raw['disbursement'];
    if (inner is Map) return tryParse(inner);
    final id = raw.text('id');
    final month = raw.yearMonth('month');
    final member = raw.text('staffMemberId');
    final validation = raw.text('validationGestureId');
    final amount = raw.integer('amountInCents');
    final currency = raw.text('currency');
    final mode = raw.text('mode');
    final paidAt = raw.instant('paidAt');
    if (id == null ||
        month == null ||
        member == null ||
        validation == null ||
        amount == null ||
        currency == null ||
        mode == null ||
        paidAt == null) {
      return null;
    }
    return PayrollDisbursementDto(
      id: id,
      month: month,
      staffMemberId: member,
      validationGestureId: validation,
      amountInCents: amount,
      currency: currency,
      mode: mode,
      paidAt: paidAt,
      operator: raw.text('operator'),
      payoutPhone: raw.text('payoutPhone'),
      reference: raw.text('reference'),
      bankName: raw.text('bankName'),
      bankAccount: raw.text('bankAccount'),
      signedRegister: raw.flag('signedRegister') ?? false,
      recordedBy: raw.text('recordedBy') ?? raw.text('by'),
      cancelledAt: raw.instant('cancelledAt'),
      cancellationReason: raw.text('cancellationReason'),
      serverUpdatedAt: raw.instant('serverUpdatedAt'),
    );
  }
}

/// `{ disbursement, authorId }`, tel que mis en file.
class PayrollDisbursementRequestDto {
  final PayrollDisbursementDto disbursement;
  final String authorId;

  const PayrollDisbursementRequestDto({
    required this.disbursement,
    required this.authorId,
  });

  Map<String, dynamic> toJson() => {
    'disbursement': disbursement.toJson(),
    kOutboxAuthorIdKey: authorId,
  };

  static PayrollDisbursementRequestDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final disbursement = PayrollDisbursementDto.tryParse(raw['disbursement']);
    final author = raw.text(kOutboxAuthorIdKey);
    if (disbursement == null || author == null) return null;
    return PayrollDisbursementRequestDto(
      disbursement: disbursement,
      authorId: author,
    );
  }
}

class PayrollDisbursementPageDto
    extends ParsedKeysetPage<PayrollDisbursementDto> {
  PayrollDisbursementPageDto._(ParsedKeysetPage<PayrollDisbursementDto> parsed)
    : super(items: parsed.items, page: parsed.page, skipped: parsed.skipped);

  factory PayrollDisbursementPageDto.fromJson(Map<String, dynamic> json) =>
      PayrollDisbursementPageDto._(
        ParsedKeysetPage.fromJson(json, PayrollDisbursementDto.tryParse),
      );
}
