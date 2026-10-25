import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';

void main() {
  group('PresenceProfile.fromWire', () {
    test('lit les cinq valeurs du contrat', () {
      expect(
        [
          'NON_EVALUE',
          'ABSENTEISTE',
          'RETARDATAIRE',
          'EXEMPLAIRE',
          'REGULIER',
        ].map(PresenceProfile.fromWire),
        PresenceProfile.values,
      );
    });

    test('une valeur inconnue ou absente se lit « non évalué »', () {
      expect(PresenceProfile.fromWire('ASSIDU'), PresenceProfile.notEvaluated);
      expect(PresenceProfile.fromWire(null), PresenceProfile.notEvaluated);
    });
  });
}
