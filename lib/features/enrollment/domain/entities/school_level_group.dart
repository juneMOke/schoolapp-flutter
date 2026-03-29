import 'package:equatable/equatable.dart';

class SchoolLevelGroup extends Equatable {
  final String id;
  final String name;
  final String? description;

  const SchoolLevelGroup({
    required this.id,
    required this.name,
    this.description,
  });

  @override
  List<Object?> get props => [id, name, description];
}
