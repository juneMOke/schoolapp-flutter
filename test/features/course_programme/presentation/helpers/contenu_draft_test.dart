import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_bloc.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/services/contenu_limits.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/contenu_draft.dart';

void main() {
  var seq = 0;
  String newId() => 'b-${seq++}';

  test('une liste se lit un élément par ligne ; un bloc vide ne part pas', () {
    final draft = ContenuDraft(const [
      ChapitreBloc(id: 'l', type: ChapitreBlocType.liste, items: ['a', 'b']),
    ], newId: newId);
    expect(draft.lines.single.controller.text, 'a\nb');

    draft.lines.single.controller.text = 'a\n\n  c  ';
    draft.add(ChapitreBlocType.paragraphe);

    expect(draft.blocs.single.items, ['a', 'c']);
    draft.dispose();
  });

  test('ordre et retrait', () {
    final draft = ContenuDraft(const [], newId: newId)..seed();
    expect(draft.lines.map((l) => l.type), [
      ChapitreBlocType.titre,
      ChapitreBlocType.paragraphe,
    ]);
    draft.move(draft.lines.last, -1);
    expect(draft.lines.first.type, ChapitreBlocType.paragraphe);
    draft.remove(draft.lines.first);
    expect(draft.lines.single.type, ChapitreBlocType.titre);
    draft.dispose();
  });

  test('plafond : pas au-delà de 200 blocs, ni de 64 Ko', () {
    final draft = ContenuDraft([
      for (var i = 0; i < ContenuLimits.maxBlocs; i++)
        ChapitreBloc(id: 'b$i', type: ChapitreBlocType.paragraphe, texte: 'x'),
    ], newId: newId);
    expect(draft.canAdd, isFalse);
    draft.add(ChapitreBlocType.titre);
    expect(draft.lines, hasLength(ContenuLimits.maxBlocs));
    draft.dispose();

    final heavy = ContenuDraft([
      ChapitreBloc(
        id: 'h',
        type: ChapitreBlocType.paragraphe,
        texte: 'é' * (ContenuLimits.maxBytes ~/ 2 + 1),
      ),
    ], newId: newId);
    expect(heavy.tooHeavy, isTrue);
    heavy.dispose();
  });
}
