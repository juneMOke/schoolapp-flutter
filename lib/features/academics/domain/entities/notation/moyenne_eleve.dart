import 'package:equatable/equatable.dart';

/// Moyenne (%) d'un élève sur une sous-période ; [moyenne] est `null` s'il n'a
/// aucune note comptée.
class MoyenneEleve extends Equatable {
  final String studentId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final double? moyenne;

  const MoyenneEleve({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.moyenne,
  });

  @override
  List<Object?> get props => [
    studentId,
    firstName,
    lastName,
    middleName,
    moyenne,
  ];
}
