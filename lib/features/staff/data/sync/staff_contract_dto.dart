import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/helpers/json_fields.dart';

/// Une période de contrat **avec** ses montants (`StaffContractDelta`) — ne
/// descend que sous `hr.pay.read`.
class StaffContractDeltaDto {
  final String id;
  final String staffMemberId;
  final String kind;
  final String? payMode;
  final String effectiveFrom;
  final String? endsOn;
  final int? amountInCents;
  final String? currency;
  final String? secopeNumber;
  final int? bonusInCents;
  final String? bonusCurrency;
  final String recordedAt;
  final String? correctedAt;
  final String? correctedByName;
  final String? replacedBy;
  final String? correctionReason;
  final int? version;
  final String? serverUpdatedAt;

  const StaffContractDeltaDto({
    required this.id,
    required this.staffMemberId,
    required this.kind,
    required this.effectiveFrom,
    required this.recordedAt,
    this.payMode,
    this.endsOn,
    this.amountInCents,
    this.currency,
    this.secopeNumber,
    this.bonusInCents,
    this.bonusCurrency,
    this.correctedAt,
    this.correctedByName,
    this.replacedBy,
    this.correctionReason,
    this.version,
    this.serverUpdatedAt,
  });

  static StaffContractDeltaDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw.text('id');
    final staffMemberId = raw.text('staffMemberId');
    final kind = raw.text('kind');
    final effectiveFrom = raw.day('effectiveFrom');
    final recordedAt = raw.instant('recordedAt');
    if (id == null ||
        staffMemberId == null ||
        kind == null ||
        effectiveFrom == null ||
        recordedAt == null) {
      return null;
    }
    return StaffContractDeltaDto(
      id: id,
      staffMemberId: staffMemberId,
      kind: kind,
      payMode: raw.text('payMode'),
      effectiveFrom: effectiveFrom,
      endsOn: raw.day('endsOn'),
      amountInCents: raw.integer('amountInCents'),
      // Devise normalisée, jamais rejetée : une devise ajoutée un jour au
      // serveur ne doit pas rendre le contrat invisible.
      currency: raw.text('currency')?.toUpperCase(),
      secopeNumber: raw.text('secopeNumber'),
      bonusInCents: raw.integer('bonusInCents'),
      bonusCurrency: raw.text('bonusCurrency')?.toUpperCase(),
      recordedAt: recordedAt,
      correctedAt: raw.instant('correctedAt'),
      correctedByName: raw.text('correctedByName'),
      replacedBy: raw.text('replacedBy'),
      correctionReason: raw.text('correctionReason'),
      version: raw.integer('version'),
      serverUpdatedAt: raw.instant('serverUpdatedAt'),
    );
  }
}

/// Page du flux `hr.staff-contracts`.
class StaffContractPageDto extends ParsedKeysetPage<StaffContractDeltaDto> {
  StaffContractPageDto._(ParsedKeysetPage<StaffContractDeltaDto> parsed)
    : super(items: parsed.items, page: parsed.page, skipped: parsed.skipped);

  factory StaffContractPageDto.fromJson(Map<String, dynamic> json) =>
      StaffContractPageDto._(
        ParsedKeysetPage.fromJson(json, StaffContractDeltaDto.tryParse),
      );
}
