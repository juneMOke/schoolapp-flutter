import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/wizard/wizard_step_progression.dart';

/// La mécanique partagée par les assistants de l'application.
///
/// Elle vit au socle parce que deux modules la lisaient — l'inscription en
/// l'inlinant dans son `build`, la mise en service en ayant besoin d'une version
/// plus riche. Deux copies auraient divergé au premier amendement, et la
/// divergence aurait porté sur ce qui est atteignable.
void main() {
  group('régime linéaire — retour libre, saut avant interdit', () {
    const progression = WizardStepProgression.linear(
      stepCount: 5,
      currentStep: 2,
    );

    test('les étapes précédentes sont franchies et atteignables', () {
      expect(progression.statusAt(0).isDone, isTrue);
      expect(progression.statusAt(0).canTap, isTrue);
      expect(progression.statusAt(1).isDone, isTrue);
    });

    test('l\'étape courante n\'est pas franchie', () {
      final current = progression.statusAt(2);
      expect(current.isCurrent, isTrue);
      expect(current.isDone, isFalse);
      expect(current.canTap, isTrue);
    });

    test('les étapes suivantes sont hors d\'atteinte', () {
      expect(progression.statusAt(3).canTap, isFalse);
      expect(progression.statusAt(4).canTap, isFalse);
      expect(progression.statusAt(3).isDone, isFalse);
    });
  });

  group('régime jalonné — on revient sur ce qu\'on a atteint', () {
    // L'utilisateur est allé jusqu'à l'étape 4, puis est revenu à la 1.
    const progression = WizardStepProgression(
      stepCount: 5,
      currentStep: 1,
      maxStep: 4,
    );

    test('revenir en arrière ne referme pas ce qui avait été ouvert', () {
      // C'est tout l'objet de `maxStep`. Sans lui, l'utilisateur qui recule
      // pour corriger une date perdrait l'accès aux trois étapes qu'il venait
      // de remplir, et devrait les re-parcourir une à une.
      expect(progression.statusAt(3).canTap, isTrue);
      expect(progression.statusAt(4).canTap, isTrue);
    });

    test('ce qui n\'a jamais été atteint reste fermé', () {
      const early = WizardStepProgression(
        stepCount: 5,
        currentStep: 1,
        maxStep: 1,
      );
      expect(early.statusAt(2).canTap, isFalse);
    });
  });

  group('étapes validées explicitement', () {
    // Assistant parcouru jusqu'au bout, puis retour à l'étape 1 pour corriger.
    const progression = WizardStepProgression(
      stepCount: 5,
      currentStep: 1,
      maxStep: 4,
      doneSteps: {0, 1, 2, 3},
    );

    test('une étape validée en aval reste franchie', () {
      // Sans `doneSteps`, les étapes 2 et 3 redeviendraient « à venir » du seul
      // fait qu'on est remonté à la 1 — ce qui effacerait à l'écran un travail
      // qui existe bel et bien.
      expect(progression.statusAt(2).isDone, isTrue);
      expect(progression.statusAt(3).isDone, isTrue);
    });

    test('l\'étape courante n\'est jamais rendue franchie', () {
      // Même déclarée valide : on la regarde, on ne l'a pas dépassée. Une
      // pastille à la fois courante et cochée est illisible.
      expect(progression.statusAt(1).isDone, isFalse);
      expect(progression.statusAt(1).isCurrent, isTrue);
    });

    test('une étape non validée en aval ne l\'est pas', () {
      expect(progression.statusAt(4).isDone, isFalse);
    });
  });

  group('traits de liaison', () {
    test('un trait n\'est actif que si ses DEUX bouts sont franchis', () {
      // Un trait qui verdit à moitié promet une progression qui n'a pas eu lieu.
      const progression = WizardStepProgression.linear(
        stepCount: 4,
        currentStep: 2,
      );
      expect(progression.connectorAfter(0), isTrue);
      expect(progression.connectorAfter(1), isFalse); // 2 est courante
      expect(progression.connectorAfter(2), isFalse);
    });

    test('le dernier rang n\'a pas de trait', () {
      const progression = WizardStepProgression.linear(
        stepCount: 3,
        currentStep: 2,
      );
      expect(progression.connectorAfter(2), isFalse);
    });
  });

  group('progression continue', () {
    test('va de 0 à 1 sur le parcours', () {
      expect(
        const WizardStepProgression.linear(
          stepCount: 5,
          currentStep: 0,
        ).progress,
        0.0,
      );
      expect(
        const WizardStepProgression.linear(
          stepCount: 5,
          currentStep: 4,
        ).progress,
        1.0,
      );
    });

    test('une étape unique est complète', () {
      expect(
        const WizardStepProgression.linear(
          stepCount: 1,
          currentStep: 0,
        ).progress,
        1.0,
      );
    });
  });
}
