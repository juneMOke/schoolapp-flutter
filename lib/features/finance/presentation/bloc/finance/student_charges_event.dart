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

/// Étape Frais du wizard en flux BROUILLON local : génère d'abord les créances
/// provisoires depuis la grille locale `ref_fee_tariffs` (FF5, idempotent par
/// élève+année), puis lit le grand-livre comme [StudentChargesRequested].
class DraftStudentChargesRequested extends StudentChargesEvent {
  final String studentId;
  final String levelId;
  final String academicYearId;
  final String? schoolLevelGroupId;

  const DraftStudentChargesRequested({
    required this.studentId,
    required this.levelId,
    required this.academicYearId,
    this.schoolLevelGroupId,
  });

  @override
  List<Object?> get props => [
    studentId,
    levelId,
    academicYearId,
    schoolLevelGroupId,
  ];
}

class StudentChargesByAcademicYearRequested extends StudentChargesEvent {
  final String studentId;
  final String academicYearId;

  const StudentChargesByAcademicYearRequested({
    required this.studentId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [studentId, academicYearId];
}

class StudentChargePaymentAllocationsRequested extends StudentChargesEvent {
  final String chargeId;

  const StudentChargePaymentAllocationsRequested({required this.chargeId});

  @override
  List<Object?> get props => [chargeId];
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
