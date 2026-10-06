import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/sujet_codecs.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';

void main() {
  group('questions', () {
    test('aller-retour, ordre = place + 1', () {
      const questions = [
        SujetQuestion(id: 'a', enonce: 'A', points: 2.5, reponseAttendue: 'r'),
        SujetQuestion(id: 'b'),
      ];

      final json = SujetCodecs.questionsToJson(questions);
      expect(json.map((q) => q['ordre']), [1, 2]);
      expect(SujetCodecs.questionsFromJson(json), questions);
    });

    test('trie par ordre et écarte une entrée sans id', () {
      final decoded = SujetCodecs.questionsFromJson([
        {'id': 'b', 'ordre': 2, 'enonce': 'B'},
        {'ordre': 3, 'enonce': 'sans id'},
        {'id': 'a', 'ordre': 1, 'enonce': 'A', 'points': 4},
        'pas une map',
      ]);
      expect(decoded.map((q) => q.id), ['a', 'b']);
      expect(decoded.first.points, 4);
    });

    test('forme illisible → liste vide', () {
      expect(SujetCodecs.questionsFromJson({'id': 'a'}), isEmpty);
      expect(SujetCodecs.decodeColumn('{pas du json'), isNull);
    });
  });

  test('programme : lignes rognées, vides retirées', () {
    expect(SujetCodecs.programmeFromJson([' A ', '', 3, 'B']), ['A', 'B']);
  });

  group('publications', () {
    test('aller-retour', () {
      final decoded = SujetCodecs.publicationsFromJson({
        'sujet': {
          'publishedAt': '2026-10-06T08:00:00Z',
          'updatedAt': null,
          'revision': 3,
        },
        'corrige': null,
      });
      expect(decoded.sujet!.revision, 3);
      expect(decoded.corrige, isNull);
      expect(
        SujetCodecs.publicationsFromJson(
          SujetCodecs.publicationsToJson(decoded),
        ),
        decoded,
      );
    });

    test('un état sans date de publication lisible vaut non publié', () {
      expect(SujetCodecs.etatFromJson({'revision': 1}), isNull);
    });
  });
}
