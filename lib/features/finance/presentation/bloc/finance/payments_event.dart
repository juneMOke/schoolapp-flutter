part of 'payments_bloc.dart';

sealed class PaymentsEvent extends Equatable {
  const PaymentsEvent();
}

class PaymentsRequested extends PaymentsEvent {
  final String studentId;
  final String academicYearId;

  const PaymentsRequested({
    required this.studentId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [studentId, academicYearId];
}