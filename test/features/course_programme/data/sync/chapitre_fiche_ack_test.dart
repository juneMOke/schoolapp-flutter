import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/push/chapitre_fiche_push.dart';

void main() {
  const chapitre = {
    'id': 'ch-1',
    'coursId': 'c-1',
    'ordre': 1,
    'titre': 'Fractions',
    'statut': 'EN_COURS',
  };

  // Forme du contrat back : `ChapitreSyncResponse(chapitre, lwwOutcome)`.
  test(
    'SUPERSEDED : la fiche envoyée a perdu, la retenue doit s\'appliquer',
    () {
      final ack = ChapitreFicheAck.fromJson({
        'chapitre': chapitre,
        'lwwOutcome': 'SUPERSEDED',
      });

      expect(ack.ignored, isTrue);
      expect(ack.chapitre.id, 'ch-1');
    },
  );

  test('APPLIED : la fiche envoyée est celle retenue', () {
    final ack = ChapitreFicheAck.fromJson({
      'chapitre': chapitre,
      'lwwOutcome': 'APPLIED',
    });

    expect(ack.ignored, isFalse);
  });

  test('sans chapitre lisible, l\'accusé lève : l\'envoi sera rejoué', () {
    expect(
      () => ChapitreFicheAck.fromJson({'lwwOutcome': 'APPLIED'}),
      throwsFormatException,
    );
  });
}
