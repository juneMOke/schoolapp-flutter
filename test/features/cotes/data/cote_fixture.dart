import 'dart:convert';

/// Une classe telle que `GET /academics/cotes` la rend : un cours avec examen,
/// un cours sans, sous une sous-rubrique.
Map<String, dynamic> coteClasseJson() =>
    jsonDecode(jsonEncode(_classe)) as Map<String, dynamic>;

const Map<String, Object?> _classe = {
  'classroomId': 'c1',
  'periodType': 'SEMESTER',
  'periodes': [
    {
      'id': 'S1',
      'ordre': 1,
      'libelle': 'Semestre 1',
      'courant': true,
      'locked': false,
      'sousPeriodes': [
        {'id': 'P1', 'ordre': 1, 'locked': false},
        {'id': 'P2', 'ordre': 2, 'locked': false},
      ],
    },
  ],
  'rubriques': [
    {
      'id': 'r1',
      'label': 'Domaine des Langues',
      'produitSousTotal': true,
      'sousRubriques': [
        {
          'id': 'r2',
          'label': 'Corps',
          'produitSousTotal': false,
          'sousRubriques': <Object?>[],
          'cours': [
            {
              'coursId': 'eps',
              'branche': 'EPS',
              'maxJournalier': 10,
              'maxExamen': 0,
            },
          ],
        },
      ],
      'cours': [
        {
          'coursId': 'fr',
          'branche': 'Français',
          'maxJournalier': 20,
          'maxExamen': 40,
        },
      ],
    },
  ],
  'eleves': [
    {
      'studentId': 'e1',
      'lastName': 'Mbaya',
      'middleName': 'Numbi',
      'firstName': 'Emmanuel',
    },
    {
      'studentId': 'e2',
      'lastName': 'Tshala',
      'middleName': null,
      'firstName': 'Sarah',
    },
  ],
  'cellules': [
    {
      'studentId': 'e1',
      'coursId': 'fr',
      'sousPeriodeId': 'P1',
      'periodeScolaireId': null,
      'cote': 14.5,
      'calculee': 13.25,
      'updatedAt': '2026-11-01T10:42:00Z',
    },
    {
      'studentId': 'e1',
      'coursId': 'fr',
      'sousPeriodeId': 'P2',
      'periodeScolaireId': null,
      'cote': null,
      'calculee': 16,
      'updatedAt': null,
    },
    {
      'studentId': 'e1',
      'coursId': 'fr',
      'sousPeriodeId': null,
      'periodeScolaireId': 'S1',
      'cote': 31,
      'calculee': null,
      'updatedAt': '2026-11-01T10:42:00Z',
    },
  ],
  'serverTime': '2026-11-01T10:43:00Z',
};
