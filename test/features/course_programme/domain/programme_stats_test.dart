import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/services/programme_stats.dart';

Chapitre _chapitre(String id, ChapitreStatut statut, {int seances = 4}) =>
    Chapitre(
      id: id,
      coursId: 'c-1',
      ordre: 0,
      titre: 'Chapitre $id',
      statut: statut,
      seances: seances,
    );

void main() {
  test('un programme vide est à 0 %', () {
    expect(ProgrammeStats.of(const []).percent, 0);
    expect(ProgrammeStats.of(const []), ProgrammeStats.empty);
  });

  test('compte par statut, somme les séances et arrondit le pourcentage', () {
    final stats = ProgrammeStats.of([
      _chapitre('1', ChapitreStatut.termine, seances: 5),
      _chapitre('2', ChapitreStatut.termine),
      _chapitre('3', ChapitreStatut.enCours),
      _chapitre('4', ChapitreStatut.planifie, seances: 6),
      _chapitre('5', ChapitreStatut.planifie),
      _chapitre('6', ChapitreStatut.planifie, seances: 5),
    ]);
    expect(stats.total, 6);
    expect(stats.termines, 2);
    expect(stats.enCours, 1);
    expect(stats.planifies, 3);
    expect(stats.seances, 28);
    expect(stats.percent, 33);
  });
}
