part of 'academic_year_previous_context_bloc.dart';

sealed class AcademicYearPreviousContextEvent extends Equatable {
  const AcademicYearPreviousContextEvent();

  @override
  List<Object?> get props => [];
}

class AcademicYearPreviousContextRequested
    extends AcademicYearPreviousContextEvent {
  const AcademicYearPreviousContextRequested();
}
