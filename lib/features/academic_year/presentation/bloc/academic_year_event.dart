part of 'academic_year_bloc.dart';

sealed class AcademicYearEvent extends Equatable {
  const AcademicYearEvent();

  @override
  List<Object?> get props => [];
}

class AcademicYearResetRequested extends AcademicYearEvent {
  const AcademicYearResetRequested();
}

class AcademicYearRemoteRequested extends AcademicYearEvent {
  final String schoolId;

  const AcademicYearRemoteRequested({required this.schoolId});

  @override
  List<Object?> get props => [schoolId];
}

class AcademicYearLocalRequested extends AcademicYearEvent {
  const AcademicYearLocalRequested();
}

class AcademicYearClearLocalRequested extends AcademicYearEvent {
  const AcademicYearClearLocalRequested();
}
