import 'package:equatable/equatable.dart';

class SchoolLevelGroup extends Equatable {
  final String id;
  final String name;
  final String code;
  final int displayOrder;

  /// Pont vers l'Académique (trimestre/semestre) — `null` si non résolu.
  final String? periodType;

  const SchoolLevelGroup({
    required this.id,
    required this.name,
    required this.code,
    this.displayOrder = 0,
    this.periodType,
  });

  @override
  List<Object?> get props => [id, name, code, displayOrder, periodType];
}
