import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_verdict.dart';

import 'simulation_test_harness.dart';

void main() {
  RecoveryVerdict? verdict(int headcount, int remaining, int below) =>
      RecoveryVerdict.of(
        simRow(
          'c1',
          '1ère',
          headcount: headcount,
          targeted: headcount - remaining,
        ),
        below,
      );

  group('RecoveryVerdict.of (R12)', () {
    test('sous le seuil : ingérable, même à 59,7 %', () {
      // 179 / 300 = 59,67 % : arrondi, il afficherait 60 et passerait.
      expect(verdict(300, 179, 60), RecoveryVerdict.unmanageable);
      expect(verdict(36, 4, 60), RecoveryVerdict.unmanageable);
    });

    test('au seuil exact : fragile', () {
      expect(verdict(300, 180, 60), RecoveryVerdict.fragile);
    });

    test('jusqu\'à 15 points au-dessus : fragile, puis tenable', () {
      expect(verdict(1000, 749, 60), RecoveryVerdict.fragile);
      expect(verdict(1000, 750, 60), RecoveryVerdict.tenable);
      expect(verdict(30, 30, 60), RecoveryVerdict.tenable);
    });

    test('le seuil suit le curseur', () {
      expect(verdict(100, 40, 30), RecoveryVerdict.fragile);
      expect(verdict(100, 46, 30), RecoveryVerdict.tenable);
      expect(verdict(100, 89, 90), RecoveryVerdict.unmanageable);
    });

    test('effectif nul ou « Non affectés » : pas de verdict', () {
      expect(verdict(0, 0, 60), isNull);
      expect(
        RecoveryVerdict.of(
          simRow(null, 'Non affectés', headcount: 6, targeted: 4),
          60,
        ),
        isNull,
      );
    });
  });

  test('la part affichée est arrondie à l\'inférieur', () {
    expect(recoveryKeptPercent(179, 300), 59);
    expect(recoveryKeptPercent(243, 478), 50);
    expect(recoveryKeptPercent(0, 0), 0);
  });
}
