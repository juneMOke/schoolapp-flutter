import 'package:equatable/equatable.dart';

/// Identité confrontée par la sonde de doublon : les trois noms et la date de
/// naissance. Rien d'autre.
///
/// Volontairement **pauvre**. Ni genre, ni lieu de naissance, ni tuteur : ce
/// sont les seuls champs sur lesquels deux sources aussi différentes qu'un
/// dossier de l'année et la cohorte N-1 s'accordent, et les seuls dont la
/// coïncidence signe vraiment un doublon.
class EnrollmentIdentity extends Equatable {
  final String lastName;
  final String firstName;

  /// Post-nom. Vide accepté : un dossier historique peut ne pas en porter,
  /// alors que l'étape Identité l'exige aujourd'hui.
  final String surname;

  /// Date de naissance **date-only** ISO, telle qu'elle est stockée
  /// (`students.date_of_birth`, `ref_previous_year_students.date_of_birth`).
  /// Vide ou illisible accepté : le rapprochement se contentera alors de ne
  /// rien confirmer.
  final String dateOfBirth;

  const EnrollmentIdentity({
    required this.lastName,
    required this.firstName,
    this.surname = '',
    this.dateOfBirth = '',
  });

  @override
  List<Object?> get props => [lastName, firstName, surname, dateOfBirth];
}
