import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_columns.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';

CotePeriode _periode(String id, int ordre, {bool courant = false}) =>
    CotePeriode(
      id: id,
      ordre: ordre,
      libelle: id,
      courant: courant,
      locked: false,
      sousPeriodes: [
        // L'`ordre` serveur repart à 1 dans chaque groupe.
        CoteSousPeriode(id: '$id-a', ordre: 1, locked: false),
        CoteSousPeriode(id: '$id-b', ordre: 2, locked: ordre == 1),
      ],
    );

void main() {
  final classe = CoteClasse(
    classroomId: 'c',
    decoupage: Decoupage.semestre,
    periodes: [_periode('S1', 1), _periode('S2', 2, courant: true)],
    rubriques: const [],
    eleves: const [],
  );

  test('les périodes se numérotent en continu sur l\'année', () {
    final numeros = yearColumns(
      classe,
    ).where((c) => c.kind == CoteColumnKind.periode).map((c) => c.numero);
    expect(numeros, [1, 2, 3, 4]);
  });

  test('un groupe : ses périodes et son examen, sans total', () {
    final columns = columnsFor(
      classe,
      const CoteScope(portee: CotePortee.groupe, cibleId: 'S2'),
    );
    expect(columns.map((c) => c.id), ['S2-a', 'S2-b', 'S2']);
  });

  test('l\'année : chaque groupe et son total', () {
    final columns = columnsFor(
      classe,
      const CoteScope(portee: CotePortee.annee),
    );
    expect(columns.length, 8);
    expect(columns[3].kind, CoteColumnKind.totalGroupe);
  });

  test('une colonne seule', () {
    final columns = columnsFor(
      classe,
      const CoteScope(portee: CotePortee.colonne, cibleId: 'S1'),
    );
    expect(columns.single.kind, CoteColumnKind.examen);
  });

  test('le verrou suit la sous-période, pas son groupe', () {
    final locked = yearColumns(
      classe,
    ).where((c) => c.isInput && c.locked).map((c) => c.id);
    expect(locked, ['S1-b']);
  });

  test('une cible disparue donne une grille vide', () {
    final columns = columnsFor(
      classe,
      const CoteScope(portee: CotePortee.groupe, cibleId: 'S9'),
    );
    expect(columns, isEmpty);
  });

  test('la portée d\'ouverture est le groupe en cours', () {
    expect(defaultScope(classe).cibleId, 'S2');
  });
}
