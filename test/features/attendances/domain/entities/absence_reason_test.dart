import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';

void main() {
  test('isUnjustified : vrai pour unjustified et unknown, faux sinon', () {
    expect(AbsenceReason.unjustified.isUnjustified, isTrue);
    expect(AbsenceReason.unknown.isUnjustified, isTrue);

    final justified = AbsenceReason.values.where(
      (r) => r != AbsenceReason.unjustified && r != AbsenceReason.unknown,
    );
    for (final reason in justified) {
      expect(
        reason.isUnjustified,
        isFalse,
        reason: '$reason ne doit pas etre injustifie',
      );
    }
  });

  group('fromApiValue — parsing défensif (invariant #9)', () {
    test('valeurs cataloguées mappées (dont UNKNOWN, distinct de OTHER)', () {
      expect(AbsenceReasonX.fromApiValue('SICKNESS'), AbsenceReason.sickness);
      expect(AbsenceReasonX.fromApiValue('UNKNOWN'), AbsenceReason.unknown);
      expect(AbsenceReasonX.fromApiValue('OTHER'), AbsenceReason.other);
      expect(AbsenceReasonX.fromApiValue('sickness'), AbsenceReason.sickness);
      expect(AbsenceReasonX.fromApiValue(null), isNull);
    });

    test(
      'motif ENRICHI côté back mais inconnu → OTHER (jamais d\'exception)',
      () {
        // Une valeur ajoutée au catalogue serveur, absente de cette tablette,
        // ne doit pas faire tomber le parsing ni retomber sur UNKNOWN.
        expect(
          AbsenceReasonX.fromApiValue('DETENTION_SUSPENSION'),
          AbsenceReason.other,
        );
      },
    );
  });
}
