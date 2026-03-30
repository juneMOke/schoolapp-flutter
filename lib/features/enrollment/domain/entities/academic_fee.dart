import 'package:equatable/equatable.dart';

class AcademicFee extends Equatable {
  final String id;
  final String name;
  final double amount;
  final String? description;
  final String levelId;
  final String academicYearId;

  const AcademicFee({
    required this.id,
    required this.name,
    required this.amount,
    this.description,
    required this.levelId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [id, name, amount, description, levelId, academicYearId];
}
