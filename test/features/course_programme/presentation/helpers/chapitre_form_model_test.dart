import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_objectif.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_ressource.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/ressource_draft.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/chapitre_form_model.dart';

/// Les règles de la modale d'un chapitre, sans widget.
void main() {
  var seq = 0;
  String newId() => 'id-${seq++}';

  ChapitreFormModel model({Chapitre? base}) => ChapitreFormModel(
    coursId: 'c-1',
    base: base,
    newId: newId,
    defaultSousPeriodeId: 'sp-1',
  );

  test('un chapitre neuf : une ligne d\'objectif vide, défauts de la spec', () {
    final m = model();
    expect(m.objectifs, hasLength(1));
    expect(m.statut, ChapitreStatut.planifie);
    expect(m.seances.text, '4');
    expect(m.sousPeriodeId, 'sp-1');
    expect(m.titreError, TitreError.required);
    expect(m.result(), isNull);
  });

  test('titre trop court, séances invalides : pas d\'édition', () {
    final m = model()..titre.text = 'ab';
    expect(m.titreError, TitreError.tooShort);
    m
      ..titre.text = 'Fractions'
      ..seances.text = '-1';
    expect(m.seancesInvalid, isTrue);
    expect(m.result(), isNull);
    m.seances.text = '';
    expect(m.result()!.chapitre.seances, 0);
  });

  test('objectifs vides ignorés, stratégies sans doublon', () {
    final m = model()..titre.text = '  Fractions  ';
    m.objectifs.single.controller.text = 'Comparer';
    m.addObjectif();
    m.strategyDraft.text = 'Tutorat';
    m.addCustomStrategy();
    m.strategyDraft.text = 'Tutorat';
    m.addCustomStrategy();
    m.toggleStrategy('Remédiation');

    final edit = m.result()!;
    expect(edit.isNew, isTrue);
    expect(edit.chapitre.titre, 'Fractions');
    expect(edit.chapitre.objectifs.map((o) => o.texte), ['Comparer']);
    expect(edit.chapitre.strategies, ['Tutorat', 'Remédiation']);
    expect(m.strategyDraft.text, isEmpty);
  });

  test(
    'une édition garde l\'identité et les acquis, et liste les retraits',
    () {
      const base = Chapitre(
        id: 'ch-1',
        coursId: 'c-1',
        ordre: 2,
        titre: 'Fractions',
        objectifs: [ChapitreObjectif(id: 'o-1', texte: 'Lire', atteint: true)],
        ressources: [
          ChapitreRessource(
            id: 'r-1',
            chapitreId: 'ch-1',
            type: RessourceType.lien,
            nom: 'A',
          ),
          ChapitreRessource(
            id: 'r-2',
            chapitreId: 'ch-1',
            type: RessourceType.manuel,
            nom: 'B',
          ),
        ],
      );
      final m = model(base: base);
      m.removeKeptRessource(m.keptRessources.first);
      m.addedRessources.add(
        const RessourceDraft(
          id: 'r-3',
          type: RessourceType.manuel,
          nom: 'C',
          reference: 'p. 4',
        ),
      );

      final edit = m.result()!;
      expect(edit.isNew, isFalse);
      expect(edit.chapitre.id, 'ch-1');
      expect(edit.chapitre.objectifs.single.atteint, isTrue);
      expect(edit.removedRessourceIds, ['r-1']);
      expect(edit.addedRessources.single.id, 'r-3');
    },
  );

  test('une ressource se valide selon son type', () {
    expect(
      const RessourceDraft(
        id: 'x',
        type: RessourceType.lien,
        nom: 'V',
        url: 'ftp://x',
      ).isValid,
      isFalse,
    );
    expect(
      const RessourceDraft(
        id: 'x',
        type: RessourceType.lien,
        nom: 'V',
        url: 'https://edu.cd/v',
      ).isValid,
      isTrue,
    );
    expect(
      const RessourceDraft(
        id: 'x',
        type: RessourceType.document,
        nom: 'F',
      ).isValid,
      isFalse,
    );
  });
}
