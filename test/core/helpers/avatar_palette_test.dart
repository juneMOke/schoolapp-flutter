import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/helpers/avatar_palette.dart';

void main() {
  group('AvatarPalette.colorFor', () {
    test('déterministe : même clé → même couleur', () {
      expect(
        AvatarPalette.colorFor('student-42'),
        AvatarPalette.colorFor('student-42'),
      );
    });

    test('clé vide → première teinte de la palette', () {
      expect(AvatarPalette.colorFor(''), AvatarPalette.palette.first);
    });

    test('toute couleur retournée appartient à la palette', () {
      for (var i = 0; i < 200; i++) {
        expect(
          AvatarPalette.palette.contains(AvatarPalette.colorFor('id-$i')),
          isTrue,
        );
      }
    });

    test('distribution : couvre toutes les teintes sur un échantillon', () {
      final seen = <int>{};
      for (var i = 0; i < 500; i++) {
        // toARGB32 évite l'usage déprécié de Color.value.
        seen.add(AvatarPalette.colorFor('eleve-$i').toARGB32());
      }
      expect(seen.length, AvatarPalette.palette.length);
    });

    test('des clés différentes peuvent donner des teintes différentes', () {
      final a = AvatarPalette.colorFor('Aaa');
      final b = AvatarPalette.colorFor('Zzz');
      // Au moins une paire distincte existe dans la palette : on vérifie que
      // le hash discrimine (sinon la palette tournante n'a aucun effet).
      final distinctes = {
        for (var i = 0; i < 50; i++) AvatarPalette.colorFor('k$i').toARGB32(),
      };
      expect(distinctes.length, greaterThan(1));
      expect(a, isNotNull);
      expect(b, isNotNull);
    });
  });
}
