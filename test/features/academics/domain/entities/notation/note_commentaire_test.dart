import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_commentaire.dart';

/// Le commentaire d'une note (V179) : null garde, "" retire, texte remplace.
void main() {
  group('edit', () {
    test('un champ vide sur une note sans commentaire n envoie rien', () {
      expect(NoteCommentaire.edit(previous: null, typed: ''), isNull);
      expect(NoteCommentaire.edit(previous: null, typed: '   '), isNull);
    });

    test('vider un commentaire existant envoie "" — et seulement alors', () {
      expect(NoteCommentaire.edit(previous: 'Bien', typed: '  '), '');
    });

    test('un texte inchangé (aux espaces près) n envoie rien', () {
      expect(NoteCommentaire.edit(previous: 'Bien', typed: ' Bien '), isNull);
    });

    test('un texte neuf part rogné', () {
      expect(
        NoteCommentaire.edit(previous: 'Bien', typed: ' Très bien '),
        'Très bien',
      );
    });
  });

  test('visible : un commentaire vidé en attente ne se montre pas', () {
    expect(NoteCommentaire.visible(''), isNull);
    expect(NoteCommentaire.visible(null), isNull);
    expect(NoteCommentaire.visible(' Bien '), 'Bien');
  });
}
