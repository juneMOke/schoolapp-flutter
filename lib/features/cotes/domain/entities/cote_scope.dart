import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';

/// Ce que l'écran montre : une colonne, un groupe (semestre ou trimestre), ou
/// toute l'année. Un filtre local : aucun rechargement.
enum CotePortee { colonne, groupe, annee }

enum CoteColumnKind { periode, examen, totalGroupe }

/// La portée et sa cible : l'id de la colonne, celui de la période, ou rien
/// pour l'année.
class CoteScope extends Equatable {
  final CotePortee portee;
  final String? cibleId;

  const CoteScope({required this.portee, this.cibleId});

  @override
  List<Object?> get props => [portee, cibleId];
}

/// Une colonne de la grille. [numero] : P1…P6 en continu sur l'année pour une
/// période, l'ordre du groupe pour un examen ou un total.
class CoteColumn extends Equatable {
  final String id;
  final CoteColumnKind kind;
  final String periodeId;
  final int numero;
  final bool locked;

  /// Nombre de sous-périodes du groupe : le maximum d'un total en dépend.
  final int sousPeriodeCount;

  const CoteColumn({
    required this.id,
    required this.kind,
    required this.periodeId,
    required this.numero,
    required this.locked,
    required this.sousPeriodeCount,
  });

  bool get isInput => kind != CoteColumnKind.totalGroupe;
  bool get isExamen => kind == CoteColumnKind.examen;

  /// Faux pour l'examen d'un cours qui n'en a pas : pas de cellule, et rien
  /// dans les notes attendues ni dans les maxima.
  bool appliesTo(CoteCours cours) => !isExamen || cours.hasExamen;

  int maxFor(CoteCours cours) => switch (kind) {
    CoteColumnKind.periode => cours.maxJournalier,
    CoteColumnKind.examen => cours.maxExamen,
    CoteColumnKind.totalGroupe =>
      sousPeriodeCount * cours.maxJournalier + cours.maxExamen,
  };

  @override
  List<Object?> get props => [
    id,
    kind,
    periodeId,
    numero,
    locked,
    sousPeriodeCount,
  ];
}
