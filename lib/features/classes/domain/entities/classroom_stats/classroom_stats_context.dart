import 'package:equatable/equatable.dart';

class ClassroomStatsContext extends Equatable {
  final String academicYearId;
  final String academicYearName;
  final DateTime generatedAt;

  const ClassroomStatsContext({
    required this.academicYearId,
    required this.academicYearName,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [academicYearId, academicYearName, generatedAt];
}
