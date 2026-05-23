import 'package:equatable/equatable.dart';

enum ClassroomMemberGender {
  male,
  female,
  other;

  static ClassroomMemberGender fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'MALE':
        return ClassroomMemberGender.male;
      case 'FEMALE':
        return ClassroomMemberGender.female;
      case 'OTHER':
        return ClassroomMemberGender.other;
      default:
        throw FormatException('Invalid classroom member gender: $value');
    }
  }
}

class ClassroomMember extends Equatable {
  final String id;
  final String studentId;
  final String classroomId;
  final String academicYearId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final ClassroomMemberGender studentGender;

  const ClassroomMember({
    required this.id,
    required this.studentId,
    required this.classroomId,
    required this.academicYearId,
    required this.studentFirstName,
    required this.studentLastName,
    this.studentMiddleName,
    required this.studentGender,
  });

  @override
  List<Object?> get props => [
    id,
    studentId,
    classroomId,
    academicYearId,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    studentGender,
  ];
}
