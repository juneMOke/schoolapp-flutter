import 'package:equatable/equatable.dart';

class ClassroomKpis extends Equatable {
  final int totalActive;
  final int activeGirls;
  final int activeBoys;
  final int inactive;

  const ClassroomKpis({
    required this.totalActive,
    required this.activeGirls,
    required this.activeBoys,
    required this.inactive,
  });

  @override
  List<Object?> get props => [totalActive, activeGirls, activeBoys, inactive];
}
