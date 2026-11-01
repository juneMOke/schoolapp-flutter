import 'package:equatable/equatable.dart';

/// Moyenne (%) d'un élève sur une sous-période ; [moyenne] est `null` s'il n'a
/// aucune note comptée.
class MoyenneEleve extends Equatable {
  final String studentId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final double? moyenne;

  /// La cote saisie pour le bulletin remplace la moyenne des évaluations.
  final bool coteSaisie;

  const MoyenneEleve({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.moyenne,
    this.coteSaisie = false,
  });

  @override
  List<Object?> get props => [
    studentId,
    firstName,
    lastName,
    middleName,
    moyenne,
    coteSaisie,
  ];
}
