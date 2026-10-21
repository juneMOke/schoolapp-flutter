import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/beneficiary_class.dart';

/// Miroir d'une entrée de `classes[]`.
class BeneficiaryClassModel {
  final String id;
  final String label;

  const BeneficiaryClassModel({required this.id, required this.label});

  factory BeneficiaryClassModel.fromJson(Map<String, dynamic> json) =>
      BeneficiaryClassModel(
        id: json['id'] as String,
        label: (json['label'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'label': label};

  BeneficiaryClass toEntity() => BeneficiaryClass(id: id, label: label);
}
