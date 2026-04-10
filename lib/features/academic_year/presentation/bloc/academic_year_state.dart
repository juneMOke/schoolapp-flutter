part of 'academic_year_bloc.dart';

const _undefined = Object();

enum AcademicYearLoadStatus { initial, loading, success, failure }

enum AcademicYearSource { remote, local }

class AcademicYearState extends Equatable {
  final AcademicYearLoadStatus status;
  final AcademicYear? academicYear;
  final AcademicYearSource? source;
  final String? errorMessage;

  const AcademicYearState({
    required this.status,
    required this.academicYear,
    required this.source,
    required this.errorMessage,
  });

  const AcademicYearState.initial()
    : status = AcademicYearLoadStatus.initial,
      academicYear = null,
      source = null,
      errorMessage = null;

  AcademicYearState copyWith({
    AcademicYearLoadStatus? status,
    Object? academicYear = _undefined,
    Object? source = _undefined,
    Object? errorMessage = _undefined,
  }) {
    return AcademicYearState(
      status: status ?? this.status,
      academicYear: identical(academicYear, _undefined)
          ? this.academicYear
          : academicYear as AcademicYear?,
      source: identical(source, _undefined) ? this.source : source as AcademicYearSource?,
      errorMessage: identical(errorMessage, _undefined)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, academicYear, source, errorMessage];
}
