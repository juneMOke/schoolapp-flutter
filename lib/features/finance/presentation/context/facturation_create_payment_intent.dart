import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';

class FacturationCreatePaymentIntent extends Equatable {
  final String studentId;
  final String academicYearId;
  final String firstName;
  final String lastName;
  final String surname;
  final String levelName;
  final String levelGroupName;
  final List<StudentCharge> studentCharges;

  const FacturationCreatePaymentIntent({
    required this.studentId,
    required this.academicYearId,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.levelName,
    required this.levelGroupName,
    required this.studentCharges,
  });

  const FacturationCreatePaymentIntent.invalid({
    required String studentId,
    required String academicYearId,
  }) : this(
         studentId: studentId,
         academicYearId: academicYearId,
         firstName: '',
         lastName: '',
         surname: '',
         levelName: '',
         levelGroupName: '',
         studentCharges: const [],
       );

  bool get hasDisplayContext =>
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty &&
      levelName.trim().isNotEmpty &&
      levelGroupName.trim().isNotEmpty;

  List<StudentCharge> get unpaidCharges =>
      studentCharges.where((c) => c.status != StudentChargeStatus.paid).toList();

  FacturationCreatePaymentIntent withRouteParams({
    required String studentId,
    required String academicYearId,
  }) => FacturationCreatePaymentIntent(
    studentId: studentId,
    academicYearId: academicYearId,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    levelName: levelName,
    levelGroupName: levelGroupName,
    studentCharges: studentCharges,
  );

  static FacturationCreatePaymentIntent fromRouteContext({
    required String studentId,
    required String academicYearId,
    Object? extra,
  }) {
    if (extra is FacturationCreatePaymentIntent) {
      return extra.withRouteParams(
        studentId: studentId,
        academicYearId: academicYearId,
      );
    }
    return FacturationCreatePaymentIntent.invalid(
      studentId: studentId,
      academicYearId: academicYearId,
    );
  }

  @override
  List<Object?> get props => [
    studentId,
    academicYearId,
    firstName,
    lastName,
    surname,
    levelName,
    levelGroupName,
    studentCharges,
  ];
}
