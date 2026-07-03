import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_eleve_ligne.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_sous_periode.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_table_sort.dart';

ResultatEleveLigne _ligne(
  String studentId,
  String prenom,
  String nom, {
  int? rang,
  bool nonClasse = false,
  double? moyenne,
  List<double?> pcts = const [],
}) => ResultatEleveLigne(
  rang: rang,
  studentId: studentId,
  nom: nom,
  prenom: prenom,
  nonClasse: nonClasse,
  moyenneGroupe: moyenne,
  pourcentages: [
    for (var i = 0; i < pcts.length; i++)
      ResultatSousPeriode(sousPeriodeId: 'sp$i', pourcentage: pcts[i]),
  ],
);

List<String> _ids(List<ResultatEleveLigne> lignes) =>
    lignes.map((l) => l.studentId).toList();

void main() {
  // A/B/D classés, C non classé. Ordre backend = [A, B, D, C].
  final a = _ligne('A', 'Alice', 'Zoe', rang: 1, moyenne: 80, pcts: [70, 40]);
  final b = _ligne('B', 'Bob', 'Adam', rang: 2, moyenne: 60, pcts: [50, 90]);
  final d = _ligne('D', 'Dan', 'Ngoy', rang: 3, moyenne: 55, pcts: [60, null]);
  final c = _ligne('C', 'Chris', 'Meyer', nonClasse: true, pcts: [null, null]);
  final lignes = [a, b, d, c];

  test('tri null → ordre backend conservé', () {
    expect(_ids(applyResultatsSort(lignes, null)), ['A', 'B', 'D', 'C']);
  });

  test('tri moyenne croissant : non classé toujours en fin', () {
    final sorted = applyResultatsSort(
      lignes,
      const ResultatsSort(field: ResultatsSortField.moyenne, ascending: true),
    );
    expect(_ids(sorted), ['D', 'B', 'A', 'C']);
  });

  test('tri moyenne décroissant : non classé toujours en fin', () {
    final sorted = applyResultatsSort(
      lignes,
      const ResultatsSort(field: ResultatsSortField.moyenne, ascending: false),
    );
    expect(_ids(sorted), ['A', 'B', 'D', 'C']);
  });

  test('tri par nom (prénom nom) croissant', () {
    final sorted = applyResultatsSort(
      lignes,
      const ResultatsSort(field: ResultatsSortField.eleve, ascending: true),
    );
    expect(_ids(sorted), ['A', 'B', 'D', 'C']);
  });

  test('tri sous-période : null en fin dans les DEUX sens', () {
    final asc = applyResultatsSort(
      lignes,
      const ResultatsSort(
        field: ResultatsSortField.sousPeriode,
        sousPeriodeIndex: 1,
        ascending: true,
      ),
    );
    // pct[1] : A=40, B=90, D=null → null en fin ; C non classé en fin.
    expect(_ids(asc), ['A', 'B', 'D', 'C']);

    final desc = applyResultatsSort(
      lignes,
      const ResultatsSort(
        field: ResultatsSortField.sousPeriode,
        sousPeriodeIndex: 1,
        ascending: false,
      ),
    );
    // desc : B=90, A=40, puis D=null (toujours en fin), C non classé.
    expect(_ids(desc), ['B', 'A', 'D', 'C']);
  });
}
