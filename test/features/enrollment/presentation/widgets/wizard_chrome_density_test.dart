import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/breadcrumb/wizard_chrome_density.dart';

void main() {
  group('WizardChromeDensity.forHeight', () {
    test('écran normal : chrome complet', () {
      expect(WizardChromeDensity.forHeight(720), WizardChromeDensity.full);
      expect(
        WizardChromeDensity.forHeight(
          AppBreakpoints.wizardStepperFullChromeMinHeight,
        ),
        WizardChromeDensity.full,
      );
    });

    test('clavier ouvert en portrait : barre réduite à sa progression', () {
      expect(WizardChromeDensity.forHeight(380), WizardChromeDensity.slim);

      const slim = WizardChromeDensity.slim;
      expect(slim.showsBreadcrumb, isTrue);
      expect(slim.usesCompactBreadcrumb, isTrue);
      expect(slim.usesFullSpacing, isFalse);
    });

    // Le cas du bug : téléphone en paysage, clavier ouvert — il ne reste que
    // ~130 dp, moins que le chrome complet ne coûte.
    test('clavier ouvert en paysage : plus de barre du tout', () {
      expect(WizardChromeDensity.forHeight(130.1), WizardChromeDensity.minimal);

      const minimal = WizardChromeDensity.minimal;
      expect(minimal.showsBreadcrumb, isFalse);
      expect(minimal.usesFullSpacing, isFalse);
    });

    test(
      'hauteur non bornée (défilement) : rien à ménager, chrome complet',
      () {
        expect(
          WizardChromeDensity.forHeight(double.infinity),
          WizardChromeDensity.full,
        );
      },
    );

    test('les paliers sont ordonnés et sans trou', () {
      expect(
        AppBreakpoints.wizardStepperBreadcrumbMinHeight,
        lessThan(AppBreakpoints.wizardStepperFullChromeMinHeight),
      );
      // Juste sous un seuil → le palier du dessous, jamais celui du dessus.
      expect(
        WizardChromeDensity.forHeight(
          AppBreakpoints.wizardStepperFullChromeMinHeight - 0.1,
        ),
        WizardChromeDensity.slim,
      );
      expect(
        WizardChromeDensity.forHeight(
          AppBreakpoints.wizardStepperBreadcrumbMinHeight - 0.1,
        ),
        WizardChromeDensity.minimal,
      );
    });
  });
}
