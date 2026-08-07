import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_input_model.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_push_models.dart';

void main() {
  group('EvaluationPushRequestModel.toJson', () {
    test('porte coursId au niveau RACINE (contrat EvaluationSyncRequest) — pas '
        'seulement dans evaluation', () {
      final json = EvaluationPushRequestModel(
        authorId: 'u1',
        coursId: 'c1',
        evaluation: EvaluationInputModel(
          id: 'ev1',
          coursId: 'c1',
          type: 'INTERRO',
          date: DateTime.utc(2026, 1, 1),
          maxPoints: 20,
          poids: 1,
        ),
      ).toJson();

      expect(json['coursId'], 'c1');
      expect(json['authorId'], 'u1');
      expect(json['evaluation'], isA<Map<String, dynamic>>());
    });

    test('round-trip fromJson/toJson conserve coursId racine', () {
      const raw = {
        'authorId': 'u1',
        'coursId': 'c1',
        'evaluation': {
          'id': 'ev1',
          'coursId': 'c1',
          'type': 'INTERRO',
          'date': '2026-01-01',
          'maxPoints': 20.0,
        },
      };

      final parsed = EvaluationPushRequestModel.fromJson(raw);

      expect(parsed.coursId, 'c1');
      expect(parsed.toJson()['coursId'], 'c1');
    });
  });
}
