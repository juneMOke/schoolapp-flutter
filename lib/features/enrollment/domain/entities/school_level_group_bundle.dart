import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';

/// Un cycle (`SchoolLevelGroup`) et ses niveaux (`SchoolLevel`), pour construire
/// les listes cycle→niveau (dropdowns cascadés, options de recherche).
class SchoolLevelGroupBundle extends Equatable {
  final SchoolLevelGroup group;
  final List<SchoolLevel> levels;

  const SchoolLevelGroupBundle({required this.group, required this.levels});

  @override
  List<Object?> get props => [group, levels];
}
