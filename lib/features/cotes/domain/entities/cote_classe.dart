import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';

/// Toute l'année d'une classe, telle que la saisie la charge
/// (`GET /academics/cotes`) : le calendrier, l'arbre du barème et les élèves
/// actifs. Les cellules vivent à part ([CoteCellTable]) : elles changent à
/// chaque frappe, pas cette structure.
class CoteClasse extends Equatable {
  final String classroomId;
  final Decoupage decoupage;
  final List<CotePeriode> periodes;
  final List<CoteRubrique> rubriques;
  final List<CoteEleve> eleves;

  const CoteClasse({
    required this.classroomId,
    required this.decoupage,
    required this.periodes,
    required this.rubriques,
    required this.eleves,
  });

  /// Les cours dans l'ordre du bulletin, sous-rubriques comprises.
  List<CoteCours> get allCours => [
    for (final rubrique in rubriques) ...rubrique.allCours,
  ];

  @override
  List<Object?> get props => [
    classroomId,
    decoupage,
    periodes,
    rubriques,
    eleves,
  ];
}

/// Un semestre ou un trimestre. [locked] vaut pour son examen.
class CotePeriode extends Equatable {
  final String id;
  final int ordre;
  final String libelle;
  final bool courant;
  final bool locked;
  final List<CoteSousPeriode> sousPeriodes;

  const CotePeriode({
    required this.id,
    required this.ordre,
    required this.libelle,
    required this.courant,
    required this.locked,
    required this.sousPeriodes,
  });

  @override
  List<Object?> get props => [
    id,
    ordre,
    libelle,
    courant,
    locked,
    sousPeriodes,
  ];
}

class CoteSousPeriode extends Equatable {
  final String id;
  final int ordre;
  final bool locked;

  const CoteSousPeriode({
    required this.id,
    required this.ordre,
    required this.locked,
  });

  @override
  List<Object?> get props => [id, ordre, locked];
}

/// Un nœud de l'arbre du barème. [label] nul sur les grilles plates : le nœud
/// ne s'affiche pas, ses cours oui.
class CoteRubrique extends Equatable {
  final String id;
  final String? label;
  final bool produitSousTotal;
  final List<CoteRubrique> sousRubriques;
  final List<CoteCours> cours;

  const CoteRubrique({
    required this.id,
    this.label,
    this.produitSousTotal = false,
    this.sousRubriques = const [],
    this.cours = const [],
  });

  List<CoteCours> get allCours => [
    ...cours,
    for (final sous in sousRubriques) ...sous.allCours,
  ];

  @override
  List<Object?> get props => [
    id,
    label,
    produitSousTotal,
    sousRubriques,
    cours,
  ];
}

/// Un cours de la classe et son barème. `maxExamen == 0` : pas d'examen.
class CoteCours extends Equatable {
  final String coursId;
  final String branche;
  final int maxJournalier;
  final int maxExamen;

  const CoteCours({
    required this.coursId,
    required this.branche,
    required this.maxJournalier,
    required this.maxExamen,
  });

  bool get hasExamen => maxExamen > 0;

  @override
  List<Object?> get props => [coursId, branche, maxJournalier, maxExamen];
}

class CoteEleve extends Equatable {
  final String studentId;
  final String lastName;
  final String? middleName;
  final String firstName;

  const CoteEleve({
    required this.studentId,
    required this.lastName,
    this.middleName,
    required this.firstName,
  });

  /// « Nom Post-nom Prénom », l'ordre des listes de la classe.
  String get fullName => [
    lastName,
    middleName,
    firstName,
  ].where((part) => part != null && part.trim().isNotEmpty).join(' ');

  @override
  List<Object?> get props => [studentId, lastName, middleName, firstName];
}
