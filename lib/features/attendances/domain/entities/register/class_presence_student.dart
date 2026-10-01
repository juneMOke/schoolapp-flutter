import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

/// Un élève de la classe, tel que l'appel le montre : identité et numéro
/// d'ordre (son rang alphabétique dans la classe — nom, post-nom, prénom).
class ClassPresenceStudent extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final StudentGender gender;

  /// Rang alphabétique dans la classe, à partir de 1.
  final int number;

  const ClassPresenceStudent({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.number,
    this.middleName,
  });

  /// « Nom Post-nom », la ligne de tête d'une carte.
  String get familyName => [
    lastName,
    middleName,
  ].where((part) => part != null && part.trim().isNotEmpty).join(' ');

  /// « Prénom Nom Post-nom », pour les annonces et les modales.
  String get fullName => '$firstName $familyName'.trim();

  /// Le rang alphabétique d'une classe : nom, post-nom, prénom, sans tenir
  /// compte de la casse.
  static int compareNames(ClassPresenceStudent a, ClassPresenceStudent b) {
    String key(ClassPresenceStudent s) =>
        '${s.lastName}\u0000${s.middleName ?? ''}\u0000${s.firstName}'
            .toLowerCase();
    return key(a).compareTo(key(b));
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    middleName,
    gender,
    number,
  ];
}
