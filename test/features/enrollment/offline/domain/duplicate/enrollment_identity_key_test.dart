import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity_key.dart';

void main() {
  group('EnrollmentIdentityKey.of', () {
    test('plie la casse et les accents', () {
      expect(EnrollmentIdentityKey.of('MUKÉNDI'), 'mukendi');
      expect(EnrollmentIdentityKey.of('José'), 'jose');
      expect(EnrollmentIdentityKey.of('Noëlla'), 'noella');
    });

    test('replie le tiret d\'un nom composé sur l\'espace', () {
      expect(
        EnrollmentIdentityKey.of('Kabeya-Mukendi'),
        EnrollmentIdentityKey.of('Kabeya Mukendi'),
      );
      expect(EnrollmentIdentityKey.of('Kabeya-Mukendi'), 'kabeya mukendi');
    });

    test('replie les deux apostrophes, droite et courbe', () {
      expect(EnrollmentIdentityKey.of("N'Guessan"), 'n guessan');
      expect(EnrollmentIdentityKey.of('N’Guessan'), 'n guessan');
      expect(
        EnrollmentIdentityKey.of("N'Guessan"),
        EnrollmentIdentityKey.of('N’Guessan'),
      );
    });

    test('réduit les espaces multiples à un seul', () {
      expect(EnrollmentIdentityKey.of('Kabeya   Mukendi'), 'kabeya mukendi');
    });

    test('absorbe l\'espace insécable d\'un copier-coller', () {
      expect(EnrollmentIdentityKey.of('Kabeya\u00a0Mukendi'), 'kabeya mukendi');
    });

    test('rogne les bords', () {
      expect(EnrollmentIdentityKey.of('  Mukendi  '), 'mukendi');
      // Un nom réduit à des séparateurs ne laisse rien derrière lui.
      expect(EnrollmentIdentityKey.of(' - '), '');
    });

    test('rend la chaîne vide pour une valeur absente ou blanche', () {
      expect(EnrollmentIdentityKey.of(null), '');
      expect(EnrollmentIdentityKey.of(''), '');
      expect(EnrollmentIdentityKey.of('   '), '');
    });

    test('les trois écritures du même nom donnent une seule clé', () {
      final keys = <String>{
        EnrollmentIdentityKey.of('Kabeya-Mukéndi'),
        EnrollmentIdentityKey.of('KABEYA MUKENDI'),
        EnrollmentIdentityKey.of('  kabeya   mukendi '),
      };
      expect(keys, hasLength(1));
    });
  });
}
