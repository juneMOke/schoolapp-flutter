import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats/school_detail.dart';

class ClassroomDetail extends Equatable {
  final SchoolDetail school;

  const ClassroomDetail({required this.school});

  @override
  List<Object?> get props => [school];
}
