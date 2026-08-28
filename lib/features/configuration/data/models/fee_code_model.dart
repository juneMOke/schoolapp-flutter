import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';

part 'fee_code_model.g.dart';

/// Un type de frais servi par `GET /finance/fee-codes`.
///
/// Le libellé peut manquer : on se rabat alors sur le code, qui est toujours
/// affichable — mieux vaut « CANTEEN » qu'une ligne vide dans un sélecteur.
@JsonSerializable(createToJson: false)
class FeeCodeModel {
  @JsonKey(defaultValue: '')
  final String code;

  final String? label;

  const FeeCodeModel({required this.code, required this.label});

  factory FeeCodeModel.fromJson(Map<String, dynamic> json) =>
      _$FeeCodeModelFromJson(json);

  FeeCodeOption toEntity() => FeeCodeOption(
    code: code,
    label: (label == null || label!.trim().isEmpty) ? code : label!.trim(),
  );
}
