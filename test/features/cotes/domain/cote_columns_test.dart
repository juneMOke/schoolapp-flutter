import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/intitule_colonne.dart';
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

  group('une grille sans examen', () {
    final etapes = CoteClasse(
      classroomId: 'c',
      decoupage: Decoupage.semestre,
      periodes: [
        for (final (id, ordre) in [('S1', 1), ('S2', 2)])
          CotePeriode(
            id: id,
            ordre: ordre,
            libelle: id,
            courant: ordre == 1,
            locked: false,
            examen: const ColonneExamen.absente(),
            sousPeriodes: [
              for (final rang in [1, 2])
                CoteSousPeriode(
                  id: '$id-$rang',
                  ordre: rang,
                  locked: false,
                  intitule: IntituleColonne(
                    libelle: 'Étape ${(ordre - 1) * 2 + rang}',
                    libelleCourt: 'É${(ordre - 1) * 2 + rang}',
                  ),
                ),
            ],
          ),
      ],
      rubriques: const [],
      eleves: const [],
    );
    const cours = CoteCours(
      coursId: 'fr',
      branche: 'Français',
      maxJournalier: 20,
      maxExamen: 0,
    );

    test('aucune colonne d\'examen, un total par groupe', () {
      final kinds = yearColumns(etapes).map((c) => c.kind).toList();

      expect(kinds.where((k) => k == CoteColumnKind.examen), isEmpty);
      expect(kinds.where((k) => k == CoteColumnKind.totalGroupe), hasLength(2));
    });

    test('le groupe ne propose que ses étapes', () {
      final columns = columnsFor(
        etapes,
        const CoteScope(portee: CotePortee.groupe, cibleId: 'S2'),
      );

      expect(columns.map((c) => c.id), ['S2-1', 'S2-2']);
      expect(columns.map((c) => c.intitule?.libelleCourt), ['É3', 'É4']);
    });

    test('le total d\'un groupe vaut la somme de ses étapes', () {
      final total = yearColumns(
        etapes,
      ).firstWhere((c) => c.kind == CoteColumnKind.totalGroupe);

      expect(total.maxFor(cours), 40);
      // Même si un cours portait un maximum d'examen, le groupe n'en a pas.
      expect(
        total.maxFor(
          const CoteCours(
            coursId: 'x',
            branche: 'X',
            maxJournalier: 20,
            maxExamen: 40,
          ),
        ),
        40,
      );
    });
  });
}
