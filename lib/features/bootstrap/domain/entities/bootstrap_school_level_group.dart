import 'package:equatable/equatable.dart';

class BootstrapSchoolLevelGroup extends Equatable {
  final String id;
  final int version;
  final String name;
  final String code;
  final String periodType;
  final int displayOrder;

  const BootstrapSchoolLevelGroup({
    required this.id,
    required this.version,
    required this.name,
    required this.code,
    required this.periodType,
    required this.displayOrder,
  });

  @override
  List<Object?> get props => [
    id,
    version,
    name,
    code,
    periodType,
    displayOrder,
  ];
}
