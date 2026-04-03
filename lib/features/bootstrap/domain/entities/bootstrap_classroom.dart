import 'package:equatable/equatable.dart';

class BootstrapClassroom extends Equatable {
  final String id;
  final int version;
  final String schoolLevelId;
  final String name;
  final int capacity;
  final int totalCount;
  final int femaleCount;
  final int maleCount;

  const BootstrapClassroom({
    required this.id,
    required this.version,
    required this.schoolLevelId,
    required this.name,
    required this.capacity,
    required this.totalCount,
    required this.femaleCount,
    required this.maleCount,
  });

  @override
  List<Object?> get props => [
    id,
    version,
    schoolLevelId,
    name,
    capacity,
    totalCount,
    femaleCount,
    maleCount,
  ];
}
