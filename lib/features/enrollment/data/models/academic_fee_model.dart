import 'package:school_app_flutter/features/enrollment/domain/entities/academic_fee.dart';

class AcademicFeeModel {
  final String id;
  final String name;
  final double amount;
  final String? description;
  final String levelId;
  final String academicYearId;

  const AcademicFeeModel({
    required this.id,
    required this.name,
    required this.amount,
    this.description,
    required this.levelId,
    required this.academicYearId,
  });

  factory AcademicFeeModel.fromJson(Map<String, dynamic> json) =>
      AcademicFeeModel(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        description: json['description'] as String?,
        levelId: json['levelId'] as String,
        academicYearId: json['academicYearId'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'amount': amount,
    'description': description,
    'levelId': levelId,
    'academicYearId': academicYearId,
  };

  AcademicFee toAcademicFee() => AcademicFee(
    id: id,
    name: name,
    amount: amount,
    description: description,
    levelId: levelId,
    academicYearId: academicYearId,
  );
}
