import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/student_suspension.dart';

/// Un élève désactivé tel que la composition des classes le montre : sa
/// période, et la classe d'origine où la réactivation le ramènera.
class SuspendedMember extends Equatable {
  final StudentSuspension suspension;
  final String classroomId;
  final String lastName;
  final String? middleName;
  final String firstName;

  const SuspendedMember({
    required this.suspension,
    required this.classroomId,
    required this.lastName,
    required this.firstName,
    this.middleName,
  });

  @override
  List<Object?> get props => [
    suspension,
    classroomId,
    lastName,
    middleName,
    firstName,
  ];
}
