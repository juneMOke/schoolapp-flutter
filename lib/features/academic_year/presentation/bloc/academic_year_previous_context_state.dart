part of 'academic_year_previous_context_bloc.dart';

enum AcademicYearPreviousContextLoadStatus {
  initial,
  loading,
  success,
  failure,
}

class AcademicYearPreviousContextState extends Equatable {
  final AcademicYearPreviousContextLoadStatus status;
  final AcademicYearContext? context;
  final String? errorMessage;

  const AcademicYearPreviousContextState({
    required this.status,
    this.context,
    this.errorMessage,
  });

  const AcademicYearPreviousContextState.initial()
    : status = AcademicYearPreviousContextLoadStatus.initial,
      context = null,
      errorMessage = null;

  /// `true` dès que la résolution a abouti — `context == null` reste un
  /// succès légitime (école dans sa première année, pas de cohorte N-1).
  bool get isResolved =>
      status == AcademicYearPreviousContextLoadStatus.success;

  AcademicYearPreviousContextState copyWith({
    AcademicYearPreviousContextLoadStatus? status,
    Object? context = const Object(),
    Object? errorMessage = const Object(),
  }) {
    return AcademicYearPreviousContextState(
      status: status ?? this.status,
      context: identical(context, const Object())
          ? this.context
          : context as AcademicYearContext?,
      errorMessage: identical(errorMessage, const Object())
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, context, errorMessage];
}
