import 'package:equatable/equatable.dart';

class SchoolLevel extends Equatable {
  final String id;
  final String name;
  final String levelGroupId;
  final String academicYearId;
  final String? description;

  const SchoolLevel({
    required this.id,
    required this.name,
    required this.levelGroupId,
    required this.academicYearId,
    this.description,
  });

  @override
  List<Object?> get props => [id, name, levelGroupId, academicYearId, description];
}
