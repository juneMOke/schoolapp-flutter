import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';

/// Une inscription enregistrée dans la journée, **nommément**.
///
/// C'est le seul bloc nominatif de l'écran, et il porte sa propre permission
/// côté serveur : lire le pilotage ne donne pas le droit de lire les noms.
class DayEnrollmentEntry extends Equatable {
  final String enrollmentId;
  final String studentId;
  final String firstName;
  final String lastName;

  /// Post-nom, convention RDC. Peut être vide.
  final String surname;

  final Gender gender;
  final String schoolLevelId;
  final String schoolLevel;
  final String cycle;

  /// Vrai pour une réinscription. C'est **ce drapeau** qui porte la vérité du
  /// type, pas le type du dossier : en production, les 363 dossiers sont tous
  /// typés `NEW_ENROLLMENT` et seuls 179 `formerStudent` distinguent les
  /// réinscriptions.
  final bool formerStudent;

  /// Date administrative déclarée — l'horloge de tout l'écran.
  final DateTime enrollmentDate;

  /// Instant de la saisie. Sert l'heure affichée, et **elle seule**.
  final DateTime createdAt;

  /// Nom de l'agent, jamais son identifiant de connexion. **Nul** quand
  /// l'annuaire ne résout pas — compte supprimé, ou écriture `SYSTEM`. On
  /// affiche alors un tiret : une attribution inventée est pire qu'absente.
  final String? recordedBy;

  const DayEnrollmentEntry({
    required this.enrollmentId,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.gender,
    required this.schoolLevelId,
    required this.schoolLevel,
    required this.cycle,
    required this.formerStudent,
    required this.enrollmentDate,
    required this.createdAt,
    this.recordedBy,
  });

  /// NOM Post-nom Prénom — l'ordre d'usage en RDC.
  String get displayName => [
    lastName,
    surname,
    firstName,
  ].where((p) => p.trim().isNotEmpty).join(' ');

  /// Vrai quand l'heure de saisie tombe le jour déclaré.
  ///
  /// Quand les deux divergent — dossier antidaté, ou poussé le soir depuis un
  /// poste hors ligne — l'heure de `createdAt` ne dit **rien** de la journée
  /// que la liste prétend montrer, et il vaut mieux ne rien afficher que
  /// d'afficher une heure fausse avec l'autorité d'une colonne.
  bool get hourIsMeaningful =>
      createdAt.year == enrollmentDate.year &&
      createdAt.month == enrollmentDate.month &&
      createdAt.day == enrollmentDate.day;

  @override
  List<Object?> get props => [
    enrollmentId,
    studentId,
    firstName,
    lastName,
    surname,
    gender,
    schoolLevelId,
    schoolLevel,
    cycle,
    formerStudent,
    enrollmentDate,
    createdAt,
    recordedBy,
  ];
}
