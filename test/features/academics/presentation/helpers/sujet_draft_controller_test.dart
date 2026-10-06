import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_bareme.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/sujet_draft_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var ids = 0;
  SujetDraftController draftOf(EvaluationSujet sujet) => SujetDraftController(
    initial: sujet,
    maxPoints: 10,
    newId: () => 'new-${ids++}',
  );

  const q1 = SujetQuestion(id: 'q1', enonce: 'Équilibrez', points: 4);
  const q2 = SujetQuestion(
    id: 'q2',
    enonce: 'Calculez',
    points: 3.5,
    reponseAttendue: '98 g/mol',
  );
  const sujet = EvaluationSujet(
    cadre: EvaluationCadre(dureeMinutes: 30),
    questions: [q1, q2],
  );

  test('un brouillon neuf n’est pas modifié, et rend le sujet', () {
    final draft = draftOf(sujet);
    expect(draft.isDirty, isFalse);
    expect(draft.questionValues, [q1, q2]);
    // 3,5 s'affiche avec la virgule décimale.
    expect(draft.questions[1].points.text, '3,5');
    expect(draft.bareme.status, BaremeStatus.under);
  });

  test('ajouter, dupliquer, déplacer, supprimer', () {
    final draft = draftOf(sujet);
    draft.duplicate(draft.questions.first);
    expect(draft.questionValues.map((q) => q.enonce), [
      'Équilibrez',
      'Équilibrez',
      'Calculez',
    ]);

    draft.move(draft.questions.last, -1);
    expect(draft.questionValues.map((q) => q.enonce), [
      'Équilibrez',
      'Calculez',
      'Équilibrez',
    ]);

    draft.remove(draft.questions.first);
    draft.addQuestion();
    expect(draft.questions, hasLength(3));
    expect(draft.isDirty, isTrue);
  });

  test('saisir des points met le barème à jour, virgule acceptée', () {
    final draft = draftOf(sujet);
    draft.questions.first.points.text = '6,5';
    expect(draft.bareme.total, 10);
    expect(draft.bareme.status, BaremeStatus.complete);
  });

  test('ajuster le maximum à la somme', () {
    final draft = draftOf(sujet);
    draft.adjustMaxToTotal();
    expect(draft.adjustedMax, 7.5);
    expect(draft.maxPoints, 7.5);
    expect(draft.isDirty, isTrue);
  });

  test('le cadre suit la durée et les consignes', () {
    final draft = draftOf(sujet);
    draft.setDuree(60);
    draft.consignes.text = 'Calculatrice';
    expect(
      draft.cadre,
      const EvaluationCadre(dureeMinutes: 60, consignes: 'Calculatrice'),
    );
  });
}
