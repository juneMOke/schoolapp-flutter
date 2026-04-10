import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_tariff.dart';

class BootstrapSchoolLevelBundle extends Equatable {
  final BootstrapSchoolLevel schoolLevel;
  final List<BootstrapClassroom> classrooms;
  final List<BootstrapTariff> tariffs;

  const BootstrapSchoolLevelBundle({
    required this.schoolLevel,
    required this.classrooms,
    required this.tariffs,
  });

  @override
  List<Object?> get props => [schoolLevel, classrooms, tariffs];
}
