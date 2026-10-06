import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/chapitre_dto.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';

void main() {
  test('lit un chapitre entier, écarte une note illisible', () {
    final dto = ChapitreDto.tryParse({
      'id': 'ch-1',
      'coursId': 'c-1',
      'ordre': 2,
      'titre': 'Fractions',
      'statut': 'TERMINE',
      'seances': 6,
      'objectifs': [
        {'id': 'o-1', 'texte': 'Comparer', 'atteint': true},
      ],
      'strategies': ['Remédiation'],
      'blocs': [
        {'id': 'b-1', 'type': 'encadre', 'texte': 'À retenir', 'items': []},
      ],
      'notes': [
        {'id': 'n-1', 'texte': 'Séance 1', 'ecriteLe': '2026-10-01T08:00:00Z'},
        {'texte': 'sans id'},
      ],
      'ressources': [
        {'id': 'r-1', 'type': 'lien', 'nom': 'Vidéo', 'url': 'https://x.y'},
      ],
    })!;

    expect(dto.notes.single.id, 'n-1');
    final chapitre = dto.toEntity();
    expect(chapitre.statut, ChapitreStatut.termine);
    expect(chapitre.objectifsAtteints, 1);
    expect(chapitre.blocs.single.type, ChapitreBlocType.encadre);
    expect(chapitre.ressources.single.detail, 'https://x.y');
  });

  test('sans identité, rien', () {
    expect(ChapitreDto.tryParse({'titre': 'x'}), isNull);
    expect(ChapitreDto.tryParse('x'), isNull);
  });
}
