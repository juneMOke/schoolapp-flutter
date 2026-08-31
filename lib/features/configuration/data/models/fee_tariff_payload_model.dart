import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/configuration/data/models/provisioning_instant.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_tariff.dart';

part 'fee_tariff_payload_model.g.dart';

/// Corps de `POST` et `PUT /finance/tariffs`.
///
/// ⚠️ **`dueAt` part SANS suffixe `Z` sur cette route**, là où
/// `/provisioning/apply` l'exige. Le serveur y attend un `LocalDateTime` : le
/// `Z` le ferait échouer. Dette de contrat assumée côté serveur — la conversion
/// vit dans [ProvisioningInstant], une fonction par route, jamais recopiée.
@JsonSerializable(createFactory: false, includeIfNull: false)
class FeeTariffPayloadModel {
  final String feeCode;
  final String label;
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String academicYearId;
  final int amountInCents;
  final String currency;
  final String? dueAt;

  const FeeTariffPayloadModel({
    required this.feeCode,
    required this.label,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    required this.academicYearId,
    required this.amountInCents,
    required this.currency,
    required this.dueAt,
  });

  factory FeeTariffPayloadModel.fromEntity(FeeTariffDraft draft) {
    final dueAt = draft.dueAt;
    return FeeTariffPayloadModel(
      feeCode: draft.feeCode,
      label: draft.label,
      schoolLevelGroupId: draft.schoolLevelGroupId,
      schoolLevelId: draft.schoolLevelId,
      academicYearId: draft.academicYearId,
      amountInCents: draft.amountInCents,
      currency: draft.currency,
      dueAt: dueAt == null ? null : ProvisioningInstant.toLocalDateTime(dueAt),
    );
  }

  Map<String, dynamic> toJson() => _$FeeTariffPayloadModelToJson(this);
}

/// Un tarif tel que le serveur le relit.
@JsonSerializable(createToJson: false)
class FeeTariffResponseModel {
  @JsonKey(defaultValue: '')
  final String id;

  @JsonKey(defaultValue: '')
  final String feeCode;

  final String? label;

  @JsonKey(defaultValue: 0)
  final int amountInCents;

  @JsonKey(defaultValue: 'USD')
  final String currency;

  final String? dueAt;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;

  const FeeTariffResponseModel({
    required this.id,
    required this.feeCode,
    required this.label,
    required this.amountInCents,
    required this.currency,
    required this.dueAt,
    required this.schoolLevelId,
    required this.schoolLevelGroupId,
  });

  factory FeeTariffResponseModel.fromJson(Map<String, dynamic> json) =>
      _$FeeTariffResponseModelFromJson(json);

  FeeTariff toEntity() => FeeTariff(
    id: id,
    feeCode: feeCode,
    label: (label == null || label!.trim().isEmpty) ? feeCode : label!.trim(),
    amountInCents: amountInCents,
    currency: currency,
    dueAt: ProvisioningInstant.parse(dueAt),
    schoolLevelId: schoolLevelId ?? '',
    schoolLevelGroupId: schoolLevelGroupId,
  );
}
