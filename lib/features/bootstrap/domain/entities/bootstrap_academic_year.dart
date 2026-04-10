import 'package:equatable/equatable.dart';

class BootstrapAcademicYear extends Equatable {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool current;

  const BootstrapAcademicYear({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.current,
  });

  @override
  List<Object?> get props => [id, name, startDate, endDate, current];
}
