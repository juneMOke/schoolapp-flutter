import 'package:equatable/equatable.dart';

sealed class ClassroomStatsEvent extends Equatable {
  const ClassroomStatsEvent();

  @override
  List<Object?> get props => [];
}

class ClassroomStatsRequested extends ClassroomStatsEvent {
  const ClassroomStatsRequested();
}

class ClassroomStatsRefreshRequested extends ClassroomStatsEvent {
  const ClassroomStatsRefreshRequested();
}

class ClassroomStatsResetRequested extends ClassroomStatsEvent {
  const ClassroomStatsResetRequested();
}
