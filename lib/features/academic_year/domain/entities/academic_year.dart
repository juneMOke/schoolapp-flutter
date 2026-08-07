import 'package:equatable/equatable.dart';

class AcademicYear extends Equatable {
  final String id;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool current;

  const AcademicYear({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    required this.current,
  });

  @override
  List<Object?> get props => [id, name, startDate, endDate, current];
}
