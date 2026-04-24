part of 'student_charges_bloc.dart';

sealed class StudentChargesEvent extends Equatable {
  const StudentChargesEvent();
}

class StudentChargesRequested extends StudentChargesEvent {
  final String studentId;
  final String levelId;

  const StudentChargesRequested({
    required this.studentId,
    required this.levelId,
  });

  @override
  List<Object?> get props => [studentId, levelId];
}

class StudentChargesDraftSaved extends StudentChargesEvent {
  final List<StudentCharge> studentCharges;

  const StudentChargesDraftSaved({required this.studentCharges});

  @override
  List<Object?> get props => [studentCharges];
}

class StudentChargeExpectedAmountUpdateRequested extends StudentChargesEvent {
  final String studentChargeId;
  final String studentId;
  final double expectedAmountInCents;

  const StudentChargeExpectedAmountUpdateRequested({
    required this.studentChargeId,
    required this.studentId,
    required this.expectedAmountInCents,
  });

  @override
  List<Object?> get props => [
    studentChargeId,
    studentId,
    expectedAmountInCents,
  ];
}
