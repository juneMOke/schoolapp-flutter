import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_input_model.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';

/// `chapitreIds` voyage intra-agrégat (régime A) : émis seulement si non vide,
/// round-trip depuis/vers la ligne locale.
void main() {
  test('toJson émet chapitreIds SSI non vide', () {
    final withChapitres = EvaluationInputModel(
      id: 'ev-1',
      coursId: 'co1',
      type: 'INTERRO',
      date: DateTime.utc(2026, 6, 10),
      maxPoints: 20,
      poids: 1,
      sousPeriodeId: 'sp1',
      chapitreIds: const ['ch1', 'ch2'],
    );
    expect(withChapitres.toJson()['chapitreIds'], ['ch1', 'ch2']);

    final withoutChapitres = EvaluationInputModel(
      id: 'ev-2',
      coursId: 'co1',
      type: 'INTERRO',
      date: DateTime.utc(2026, 6, 10),
      maxPoints: 20,
      poids: 1,
      sousPeriodeId: 'sp1',
    );
    expect(withoutChapitres.toJson().containsKey('chapitreIds'), isFalse);
  });

  test('fromJson parse chapitreIds ; absent → liste vide', () {
    final parsed = EvaluationInputModel.fromJson(const {
      'id': 'ev-1',
      'coursId': 'co1',
      'type': 'INTERRO',
      'date': '2026-06-10',
      'maxPoints': 20,
      'sousPeriodeId': 'sp1',
      'chapitreIds': ['ch1'],
    });
    expect(parsed.chapitreIds, ['ch1']);

    final withoutField = EvaluationInputModel.fromJson(const {
      'id': 'ev-2',
      'coursId': 'co1',
      'type': 'INTERRO',
      'date': '2026-06-10',
      'maxPoints': 20,
    });
    expect(withoutField.chapitreIds, isEmpty);
  });

  test('fromRow reprend chapitreIds décodés depuis la ligne locale', () {
    final row = EvaluationRow(
      id: 'ev-1',
      coursId: 'co1',
      type: 'INTERRO',
      evalDate: 0,
      maxPoints: 20,
      poids: 1,
      sousPeriodeId: 'sp1',
      updatedAt: 1,
      chapitreIdsJson: EvaluationRow.encodeChapitreIds(['ch1', 'ch2']),
    );

    expect(EvaluationInputModel.fromRow(row).chapitreIds, ['ch1', 'ch2']);
  });
}
