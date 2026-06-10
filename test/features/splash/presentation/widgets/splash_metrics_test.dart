import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/splash/presentation/widgets/splash_metrics.dart';

void main() {
  SplashMetrics metricsFor(double width, double height) {
    final size = Size(width, height);
    return SplashMetrics.fromMedia(
      size: size,
      orientation: width >= height
          ? Orientation.landscape
          : Orientation.portrait,
    );
  }

  group('SplashMetrics — format responsive', () {
    test(
      'téléphone portrait (390×844) → phonePortrait, symbole 112, empilé',
      () {
        final m = metricsFor(390, 844);
        expect(m.format, SplashFormat.phonePortrait);
        expect(m.symbolDiameter, 112);
        expect(m.progressWidth, 96);
        expect(m.isRow, isFalse);
        expect(m.showFooter, isTrue);
      },
    );

    test(
      'téléphone paysage (844×390) → phoneLandscape, symbole 96, en ligne',
      () {
        final m = metricsFor(844, 390);
        // shortestSide = 390 < 600 → reste un téléphone malgré largeur ≥ 600.
        expect(m.format, SplashFormat.phoneLandscape);
        expect(m.symbolDiameter, 96);
        expect(m.progressWidth, 96);
        expect(m.isRow, isTrue);
      },
    );

    test('tablette portrait (768×1024) → tablet, symbole 152, empilé', () {
      final m = metricsFor(768, 1024);
      expect(m.format, SplashFormat.tablet);
      expect(m.symbolDiameter, 152);
      expect(m.progressWidth, 130);
      expect(m.isRow, isFalse);
    });

    test('bureau (1440×900) → desktop, symbole 180', () {
      final m = metricsFor(1440, 900);
      expect(m.format, SplashFormat.desktop);
      expect(m.symbolDiameter, 180);
      expect(m.progressWidth, 150);
      expect(m.isRow, isFalse);
    });
  });

  group('SplashMetrics — plafonds & garde-fous', () {
    test('plafond 38 % du petit côté sur très petit écran', () {
      // shortestSide = 240 → 0.38 × 240 = 91.2 < 112 (valeur du format).
      final m = metricsFor(240, 500);
      expect(m.format, SplashFormat.phonePortrait);
      expect(m.symbolDiameter, closeTo(91.2, 0.001));
    });

    test('plafond absolu 200 dp jamais dépassé', () {
      // Très grand écran : 0.38 × shortestSide ≫ 200, format desktop = 180.
      final m = metricsFor(3000, 2000);
      expect(m.symbolDiameter, lessThanOrEqualTo(SplashMetrics.symbolHardCap));
      expect(m.symbolDiameter, 180);
    });

    test('pied masqué sous 360 dp de hauteur', () {
      final tooShort = metricsFor(844, 320);
      expect(tooShort.showFooter, isFalse);

      final tallEnough = metricsFor(844, 360);
      expect(tallEnough.showFooter, isTrue);
    });
  });
}
