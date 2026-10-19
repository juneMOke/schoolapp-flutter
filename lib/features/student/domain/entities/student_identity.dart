import 'package:equatable/equatable.dart';

/// De qui parle-t-on, et dans quelle classe cette année : ce qu'une fiche
/// ouverte par son adresse (lien collé, onglet rechargé) doit retrouver seule.
class StudentIdentity extends Equatable {
  final String studentId;
  final String firstName;
  final String lastName;
  final String surname;

  /// Code brut du référentiel (`MALE`, `FEMALE`…), tel que la base le garde.
  final String gender;

  /// Niveau et cycle de l'inscription de l'année ; vides sans inscription.
  final String levelName;
  final String levelGroupName;

  const StudentIdentity({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.surname = '',
    this.gender = '',
    this.levelName = '',
    this.levelGroupName = '',
  });

  @override
  List<Object?> get props => [
    studentId,
    firstName,
    lastName,
    surname,
    gender,
    levelName,
    levelGroupName,
  ];
}
