import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';

/// Correction d'un dossier déjà complété : ce que l'écran ouvre, et ce qu'il
/// garde fermé.
void main() {
  const policy = CompletedReeditionDetailPolicy(
    enrollmentType: 'RE_ENROLLMENT',
  );

  group('ce qui s\'ouvre', () {
    test('l\'identité, l\'adresse, les antécédents et les tuteurs', () {
      expect(policy.isStepEditable(EnrollmentWizardStep.personalInfo), isTrue);
      expect(policy.isStepEditable(EnrollmentWizardStep.address), isTrue);
      expect(
        policy.isStepEditable(EnrollmentWizardStep.previousAcademic),
        isTrue,
      );
      expect(policy.isStepEditable(EnrollmentWizardStep.guardian), isTrue);
    });

    test('l\'écran n\'est donc pas une consultation', () {
      expect(policy.isReadOnlyConsultation, isFalse);
      expect(policy.usesLocalDraft, isTrue);
    });
  });

  group('ce qui reste fermé', () {
    /// Les créances sont projetées une fois, et leur matérialisation est
    /// idempotente : un niveau changé après coup laisserait l'élève inscrit
    /// dans un niveau et facturé sur la grille d'un autre. Le serveur refuse
    /// d'ailleurs le changement (422) — l'écran n'invite pas à une saisie qui
    /// serait rejetée.
    test('la classe cible et les frais', () {
      expect(
        policy.isStepEditable(EnrollmentWizardStep.targetAcademic),
        isFalse,
      );
      expect(
        policy.isStepEditable(EnrollmentWizardStep.studentCharges),
        isFalse,
      );
      expect(policy.canSaveStep(EnrollmentWizardStep.targetAcademic), isFalse);
      expect(policy.canSaveStep(EnrollmentWizardStep.studentCharges), isFalse);
    });

    test('le récapitulatif reste actionnable : c\'est lui qui valide', () {
      expect(policy.isStepEditable(EnrollmentWizardStep.summary), isFalse);
      expect(policy.canSaveStep(EnrollmentWizardStep.summary), isTrue);
    });
  });

  group('ce que la validation écrit', () {
    /// `IN_PROGRESS` est l'état LOCAL d'un dossier corrigé et remis dans la
    /// file, pas encore parti. Le serveur re-dérive `COMPLETED` à l'ingestion.
    test('IN_PROGRESS, et le type réel du dossier est conservé', () {
      expect(policy.finalizeStatus, 'IN_PROGRESS');
      expect(policy.draftEnrollmentType, 'RE_ENROLLMENT');
    });

    test('sans type porté, le défaut NEW s\'applique', () {
      expect(
        const CompletedReeditionDetailPolicy().draftEnrollmentType,
        'NEW_ENROLLMENT',
      );
    });
  });

  /// L'écran est rendu depuis l'agrégat local entier, pas depuis le détail de
  /// brouillon : relire le mauvais des deux laisserait l'écran sur les données
  /// d'avant la correction — enregistrée en base, invisible à l'écran.
  test('la ré-hydratation relit l\'agrégat local, et elle seule', () {
    expect(policy.refreshesFromLocalAggregate, isTrue);
    expect(
      const LocalDraftResumeDetailPolicy().refreshesFromLocalAggregate,
      isFalse,
    );
    expect(
      const NewFirstRegistrationDetailPolicy().refreshesFromLocalAggregate,
      isFalse,
    );
  });

  test('l\'origine résout bien vers cette politique', () {
    final resolved = EnrollmentDetailPolicyResolver.fromIntent(
      const EnrollmentDetailIntent.completedReedition(
        enrollmentId: 'e1',
        enrollmentType: 'NEW_ENROLLMENT',
      ),
    );

    expect(resolved, isA<CompletedReeditionDetailPolicy>());
    expect(resolved.finalizeStatus, 'IN_PROGRESS');
  });

  /// Le dossier est déjà en base : le photographier une seconde fois écraserait
  /// la correction en cours par la version d'origine.
  test('aucun seed : l\'agrégat est déjà local', () {
    expect(policy.requiresDraftSeed, isFalse);
    expect(policy.seedsFromLocalRef, isFalse);
  });
}
