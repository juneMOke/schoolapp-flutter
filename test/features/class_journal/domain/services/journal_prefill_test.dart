import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_prefill.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_objectif.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_ressource.dart';

import '../../journal_fixtures.dart';

void main() {
  const chapitre = Chapitre(
    id: 'ch',
    coursId: 'c',
    ordre: 2,
    titre: 'Aires des figures planes',
    objectifs: [
      ChapitreObjectif(id: 'o1', texte: 'Calculer un périmètre', atteint: true),
      ChapitreObjectif(id: 'o2', texte: 'Calculer l\'aire d\'un triangle'),
    ],
    strategies: ['Questionnement', 'Travail en groupe'],
    ressources: [
      ChapitreRessource(
        id: 'r1',
        chapitreId: 'ch',
        type: RessourceType.manuel,
        nom: 'Manuel p. 42',
      ),
      ChapitreRessource(
        id: 'r2',
        chapitreId: 'ch',
        type: RessourceType.lien,
        nom: 'Vidéo',
      ),
    ],
  );

  test(
    'reprend le 1er objectif non atteint, le titre, stratégies, ressources',
    () {
      final fields = JournalPrefill.fromChapitre(chapitre);

      expect(fields.objectif, 'Calculer l\'aire d\'un triangle');
      expect(fields.contenu, 'Aires des figures planes');
      expect(fields.strategie, 'Questionnement, Travail en groupe');
      expect(fields.ressources, 'Manuel p. 42 ; Vidéo');
    },
  );

  test('tous atteints : le premier objectif', () {
    final fields = JournalPrefill.fromChapitre(
      chapitre.copyWith(
        objectifs: const [
          ChapitreObjectif(id: 'o1', texte: 'Premier', atteint: true),
        ],
      ),
    );

    expect(fields.objectif, 'Premier');
  });

  test('C.B, évaluation et observation restent celles de la saisie', () {
    final fields = JournalPrefill.fromChapitre(
      chapitre,
      current: const JournalFields(
        cb: 'Résoudre',
        evaluation: 'Ex. 1',
        observation: 'RAS',
        objectif: 'ancien',
      ),
    );

    expect(fields.cb, 'Résoudre');
    expect(fields.evaluation, 'Ex. 1');
    expect(fields.observation, 'RAS');
    expect(fields.objectif, isNot('ancien'));
  });

  test('dernière C.B du cours : la plus récente non vide', () {
    final slotOrder = {for (final s in kSchoolSlots) s.id: s.order};
    final cb = JournalPrefill.lastCb([
      entryOf(
        coursId: 'c',
        date: DateTime(2026, 10, 12),
        slot: 's1',
        fields: const JournalFields(cb: 'Ancienne'),
      ),
      entryOf(
        coursId: 'c',
        date: DateTime(2026, 10, 13),
        slot: 's3',
        fields: const JournalFields(cb: 'Récente'),
      ),
      entryOf(coursId: 'c', date: DateTime(2026, 10, 14), slot: 's1'),
    ], slotOrder: slotOrder);

    expect(cb, 'Récente');
    expect(JournalPrefill.lastCb(const [], slotOrder: slotOrder), isEmpty);
  });
}
