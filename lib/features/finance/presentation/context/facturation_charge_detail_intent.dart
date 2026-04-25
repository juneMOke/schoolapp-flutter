import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';

class FacturationChargeDetailIntent extends Equatable {
  final String chargeId;
  final String studentId;
  final String academicYearId;
  // Student display fields
  final String firstName;
  final String lastName;
  final String surname;
  final String levelName;
  final String levelGroupName;
  // Charge detail fields
  final String chargeLabel;
  final double expectedAmountInCents;
  final double amountPaidInCents;
  final String currency;
  final StudentChargeStatus chargeStatus;

  const FacturationChargeDetailIntent({
    required this.chargeId,
    required this.studentId,
    required this.academicYearId,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.levelName,
    required this.levelGroupName,
    required this.chargeLabel,
    required this.expectedAmountInCents,
    required this.amountPaidInCents,
    required this.currency,
    required this.chargeStatus,
  });

  const FacturationChargeDetailIntent.invalid({
    required String chargeId,
    required String studentId,
    required String academicYearId,
  }) : this(
         chargeId: chargeId,
         studentId: studentId,
         academicYearId: academicYearId,
         firstName: '',
         lastName: '',
         surname: '',
         levelName: '',
         levelGroupName: '',
         chargeLabel: '',
         expectedAmountInCents: 0,
         amountPaidInCents: 0,
         currency: '',
         chargeStatus: StudentChargeStatus.due,
       );

  bool get hasDisplayContext =>
      chargeId.trim().isNotEmpty &&
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty &&
      levelName.trim().isNotEmpty &&
      levelGroupName.trim().isNotEmpty;

  FacturationChargeDetailIntent withRouteParams({
    required String chargeId,
    required String studentId,
    required String academicYearId,
  }) => FacturationChargeDetailIntent(
    chargeId: chargeId,
    studentId: studentId,
    academicYearId: academicYearId,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    levelName: levelName,
    levelGroupName: levelGroupName,
    chargeLabel: chargeLabel,
    expectedAmountInCents: expectedAmountInCents,
    amountPaidInCents: amountPaidInCents,
    currency: currency,
    chargeStatus: chargeStatus,
  );

  static FacturationChargeDetailIntent fromRouteContext({
    required String chargeId,
    required String studentId,
    required String academicYearId,
    Object? extra,
  }) {
    if (extra is FacturationChargeDetailIntent) {
      return extra.withRouteParams(
        chargeId: chargeId,
        studentId: studentId,
        academicYearId: academicYearId,
      );
    }
    return FacturationChargeDetailIntent.invalid(
      chargeId: chargeId,
      studentId: studentId,
      academicYearId: academicYearId,
    );
  }

  @override
  List<Object?> get props => [
    chargeId,
    studentId,
    academicYearId,
    firstName,
    lastName,
    surname,
    levelName,
    levelGroupName,
    chargeLabel,
    expectedAmountInCents,
    amountPaidInCents,
    currency,
    chargeStatus,
  ];
}
