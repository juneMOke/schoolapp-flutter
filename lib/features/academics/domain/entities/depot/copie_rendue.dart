import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/depot_copie.dart';

/// Où en est un élève pour un devoir en ligne.
enum EtatRendu { rendu, renduEnRetard, pasRendu }

/// Un élève de la classe et sa copie, s'il en a déposé une.
class CopieRendue extends Equatable {
  final String studentId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final DepotCopie? depot;

  const CopieRendue({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.depot,
  });

  EtatRendu get etat => switch (depot) {
    null => EtatRendu.pasRendu,
    DepotCopie(enRetard: true) => EtatRendu.renduEnRetard,
    _ => EtatRendu.rendu,
  };

  /// « Nom Post-nom Prénom », l'ordre des listes d'élèves.
  String get name => [
    lastName,
    middleName,
    firstName,
  ].where((part) => part != null && part.trim().isNotEmpty).join(' ');

  @override
  List<Object?> get props => [
    studentId,
    firstName,
    lastName,
    middleName,
    depot,
  ];
}

/// La classe face à un devoir en ligne : qui a rendu, et combien.
class CopiesRendues extends Equatable {
  final List<CopieRendue> eleves;

  const CopiesRendues(this.eleves);

  static const CopiesRendues empty = CopiesRendues([]);

  int get rendues => eleves.where((e) => e.depot != null).length;

  int get total => eleves.length;

  @override
  List<Object?> get props => [eleves];
}
