import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/crop_window.dart';

void main() {
  group('CropWindow', () {
    test('centré : le plus grand carré, au milieu', () {
      final w = CropWindow.centered(400, 300);
      expect(w.side, 300);
      expect(w.left, 50);
      expect(w.top, 0);
    });

    test(
      'le guide ovale : 78 % du petit côté, centré à 46 % de la hauteur',
      () {
        final w = CropWindow.ovalGuide(1000, 800);
        expect(w.side, closeTo(624, 0.01));
        expect(w.centerX, 500);
        expect(w.centerY, closeTo(368, 0.01));
      },
    );

    test(
      'le carré ne sort jamais de l\'image, quel que soit le glissement',
      () {
        var w = CropWindow.centered(400, 300).zoomTo(2);
        w = w.panBy(10000, 10000, 300);
        expect(w.left, 0);
        expect(w.top, 0);
        w = w.panBy(-10000, -10000, 300);
        expect(w.left + w.side, 400);
        expect(w.top + w.side, 300);
      },
    );

    test('glisser vers la droite montre ce qui est à gauche', () {
      final w = CropWindow.centered(600, 300).panBy(30, 0, 300);
      // 300 px d'image pour 300 dp : 1 px par dp.
      expect(w.centerX, 300 - 30);
    });

    test('le zoom est borné de 1× à 3×', () {
      final w = CropWindow.centered(300, 300);
      expect(w.zoomTo(0.2).zoom, 1);
      expect(w.zoomTo(9).zoom, 3);
      expect(w.zoomTo(3).side, 100);
    });

    test('la fraction rend le carré en proportions de l\'image', () {
      final f = CropWindow.centered(400, 200).fraction;
      expect(f.left, 0.25);
      expect(f.top, 0);
      expect(f.width, 0.5);
      expect(f.height, 1);
    });
  });
}
