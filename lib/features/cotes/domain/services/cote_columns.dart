import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';

/// Toutes les colonnes de l'année, totaux de groupe compris, dans l'ordre du
/// bulletin. Le numéro de période court sur l'année, quel que soit l'`ordre`
/// serveur de la sous-période.
List<CoteColumn> yearColumns(CoteClasse classe) {
  final columns = <CoteColumn>[];
  var numero = 0;
  for (final periode in classe.periodes) {
    final count = periode.sousPeriodes.length;
    for (final sousPeriode in periode.sousPeriodes) {
      numero++;
      columns.add(
        CoteColumn(
          id: sousPeriode.id,
          kind: CoteColumnKind.periode,
          periodeId: periode.id,
          numero: numero,
          locked: sousPeriode.locked,
          sousPeriodeCount: count,
        ),
      );
    }
    columns
      ..add(
        CoteColumn(
          id: periode.id,
          kind: CoteColumnKind.examen,
          periodeId: periode.id,
          numero: periode.ordre,
          locked: periode.locked,
          sousPeriodeCount: count,
        ),
      )
      ..add(
        CoteColumn(
          id: 'TOT:${periode.id}',
          kind: CoteColumnKind.totalGroupe,
          periodeId: periode.id,
          numero: periode.ordre,
          locked: true,
          sousPeriodeCount: count,
        ),
      );
  }
  return columns;
}

/// Les colonnes d'une portée. `groupe` n'a pas de colonne de total : la
/// dernière colonne de la grille la porte déjà. Une cible qui n'existe plus
/// donne une grille vide, jamais une erreur.
List<CoteColumn> columnsFor(CoteClasse classe, CoteScope scope) {
  final year = yearColumns(classe);
  return switch (scope.portee) {
    CotePortee.annee => year,
    CotePortee.groupe =>
      year
          .where((c) => c.isInput && c.periodeId == scope.cibleId)
          .toList(growable: false),
    CotePortee.colonne =>
      year
          .where((c) => c.isInput && c.id == scope.cibleId)
          .toList(growable: false),
  };
}

/// La portée d'ouverture : le groupe en cours, sinon le premier. Avec
/// [singleColumn], sa première colonne ouverte : un téléphone n'en montre
/// qu'une à la fois.
CoteScope defaultScope(CoteClasse classe, {bool singleColumn = false}) {
  final periodes = classe.periodes;
  if (periodes.isEmpty) return const CoteScope(portee: CotePortee.annee);
  final courant = periodes.where((p) => p.courant);
  final periode = courant.isEmpty ? periodes.first : courant.first;
  if (!singleColumn) {
    return CoteScope(portee: CotePortee.groupe, cibleId: periode.id);
  }
  final columns = yearColumns(
    classe,
  ).where((c) => c.isInput && c.periodeId == periode.id);
  final open = columns.where((c) => !c.locked);
  final column = open.isEmpty ? columns.first : open.first;
  return CoteScope(portee: CotePortee.colonne, cibleId: column.id);
}
