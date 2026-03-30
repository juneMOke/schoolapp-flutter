import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';

class StudentSummary extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String surname;
  final String dateOfBirth;
  final Gender gender;

  const StudentSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.dateOfBirth,
    required this.gender,
  });

  @override
  List<Object?> get props => [id, firstName, lastName, surname, dateOfBirth, gender];
}
