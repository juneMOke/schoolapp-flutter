import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';

void main() {
  group('EnrollmentDetailPolicyResolver - first registration', () {
    test('status COMPLETED => read-only for editable steps', () {
      const intent = EnrollmentDetailIntent(
        origin: EnrollmentDetailOrigin.firstRegistration,
        enrollmentId: 'e1',
        status: 'COMPLETED',
      );
      final policy = EnrollmentDetailPolicyResolver.fromIntent(intent);

      expect(policy.isStepEditable(EnrollmentWizardStep.personalInfo), isFalse);
      expect(policy.isStepEditable(EnrollmentWizardStep.address), isFalse);
      expect(policy.isStepEditable(EnrollmentWizardStep.summary), isFalse);
    });

    test('status IN_PROGRESS => editable except summary', () {
      const intent = EnrollmentDetailIntent(
        origin: EnrollmentDetailOrigin.firstRegistration,
        enrollmentId: 'e1',
        status: 'IN_PROGRESS',
      );
      final policy = EnrollmentDetailPolicyResolver.fromIntent(intent);

      expect(policy.isStepEditable(EnrollmentWizardStep.personalInfo), isTrue);
      expect(policy.isStepEditable(EnrollmentWizardStep.address), isTrue);
      expect(policy.isStepEditable(EnrollmentWizardStep.summary), isFalse);
    });
  });

  group('parcours brouillon offline-first (convergence)', () {
    const reIntent = EnrollmentDetailIntent.reRegistration(
      enrollmentId: 'e-re',
      studentId: 'stu-1',
    );
    const preIntent = EnrollmentDetailIntent.preRegistration(
      enrollmentId: 'e-pre',
    );
    const newIntent = EnrollmentDetailIntent.newFirstRegistration();

    test('toute création/édition écrit dans le brouillon local', () {
      expect(
        EnrollmentDetailPolicyResolver.fromIntent(newIntent).usesLocalDraft,
        isTrue,
      );
      expect(
        EnrollmentDetailPolicyResolver.fromIntent(reIntent).usesLocalDraft,
        isTrue,
      );
      expect(
        EnrollmentDetailPolicyResolver.fromIntent(preIntent).usesLocalDraft,
        isTrue,
      );
      expect(
        EnrollmentDetailPolicyResolver.fromIntent(
          const EnrollmentDetailIntent(
            origin: EnrollmentDetailOrigin.firstRegistration,
            enrollmentId: 'e1',
            status: 'IN_PROGRESS',
          ),
        ).usesLocalDraft,
        isTrue,
      );
    });

    test('la consultation pure ne touche jamais le brouillon', () {
      final policy = EnrollmentDetailPolicyResolver.fromIntent(
        const EnrollmentDetailIntent(
          origin: EnrollmentDetailOrigin.firstRegistration,
          enrollmentId: 'e1',
          status: 'COMPLETED',
        ),
      );
      expect(policy.usesLocalDraft, isFalse);
      expect(policy.requiresDraftSeed, isFalse);
    });

    test('seed requis pour RE/PRE/reprise, jamais pour NEW (vierge)', () {
      expect(
        EnrollmentDetailPolicyResolver.fromIntent(newIntent).requiresDraftSeed,
        isFalse,
      );
      expect(
        EnrollmentDetailPolicyResolver.fromIntent(reIntent).requiresDraftSeed,
        isTrue,
      );
      expect(
        EnrollmentDetailPolicyResolver.fromIntent(preIntent).requiresDraftSeed,
        isTrue,
      );
      expect(
        EnrollmentDetailPolicyResolver.fromIntent(
          const EnrollmentDetailIntent(
            origin: EnrollmentDetailOrigin.firstRegistration,
            enrollmentId: 'e1',
            status: 'IN_PROGRESS',
          ),
        ).requiresDraftSeed,
        isTrue,
      );
    });

    test('triplet type/statut du brouillon par origine', () {
      final re = EnrollmentDetailPolicyResolver.fromIntent(reIntent);
      expect(re.draftEnrollmentType, 'RE_ENROLLMENT');
      expect(re.draftStatus, 'IN_PROGRESS');

      final pre = EnrollmentDetailPolicyResolver.fromIntent(preIntent);
      expect(pre.draftEnrollmentType, 'PRE_ENROLLMENT');
      expect(pre.draftStatus, 'PRE_REGISTERED');

      final anew = EnrollmentDetailPolicyResolver.fromIntent(newIntent);
      expect(anew.draftEnrollmentType, 'NEW_ENROLLMENT');
      expect(anew.draftStatus, 'IN_PROGRESS');
    });

    test(
      'PRE conserve l\'id serveur (idempotence) et le pose en sourceRef',
      () {
        final pre = EnrollmentDetailPolicyResolver.fromIntent(preIntent);
        expect(pre.seedEnrollmentId(preIntent), 'e-pre');
        expect(pre.seedSourceRef(preIntent), 'e-pre');
      },
    );

    test('RE : id neuf (nouveau dossier année N), sourceRef différé au seed '
        'cohorte locale', () {
      final re = EnrollmentDetailPolicyResolver.fromIntent(reIntent);
      expect(re.seedEnrollmentId(reIntent), isNull);
      expect(re.seedSourceRef(reIntent), isNull);
    });

    test('reprise IN_PROGRESS : conserve l\'id serveur du dossier', () {
      const intent = EnrollmentDetailIntent(
        origin: EnrollmentDetailOrigin.firstRegistration,
        enrollmentId: 'e-srv',
        status: 'IN_PROGRESS',
      );
      final policy = EnrollmentDetailPolicyResolver.fromIntent(intent);
      expect(policy.seedEnrollmentId(intent), 'e-srv');
      expect(policy.seedSourceRef(intent), isNull);
    });
  });

  group('reprise d\'un brouillon LOCAL (localDraftResume)', () {
    const intent = EnrollmentDetailIntent.localDraftResume(
      enrollmentId: 'draft-1',
      studentId: 'stu-1',
    );

    test('résout vers LocalDraftResumeDetailPolicy', () {
      expect(
        EnrollmentDetailPolicyResolver.fromIntent(intent),
        isA<LocalDraftResumeDetailPolicy>(),
      );
    });

    test(
      'éditable partout sauf le récapitulatif (comme NEW) → usesLocalDraft',
      () {
        final policy = EnrollmentDetailPolicyResolver.fromIntent(intent);
        expect(
          policy.isStepEditable(EnrollmentWizardStep.personalInfo),
          isTrue,
        );
        expect(policy.isStepEditable(EnrollmentWizardStep.guardian), isTrue);
        expect(policy.isStepEditable(EnrollmentWizardStep.summary), isFalse);
        expect(policy.usesLocalDraft, isTrue);
        expect(policy.isReadOnlyConsultation, isFalse);
      },
    );

    test('AUCUN seed : l\'agrégat est déjà en base locale', () {
      final policy = EnrollmentDetailPolicyResolver.fromIntent(intent);
      // Ni seed serveur ni seed cohorte/préinscription : la page charge le
      // brouillon par id (LoadDraftDetailRequested), pas via un seed.
      expect(policy.requiresDraftSeed, isFalse);
      expect(policy.seedsFromLocalRef, isFalse);
      expect(policy.seedEnrollmentId(intent), isNull);
      expect(policy.seedSourceRef(intent), isNull);
    });

    test('sans enrollmentType (intent minimal) → défauts NEW/IN_PROGRESS', () {
      final policy = EnrollmentDetailPolicyResolver.fromIntent(intent);
      expect(policy.draftEnrollmentType, 'NEW_ENROLLMENT');
      expect(policy.draftStatus, 'IN_PROGRESS');
    });

    test('reprise d\'un brouillon RE : préserve RE_ENROLLMENT/IN_PROGRESS '
        '(ne requalifie jamais en NEW_ENROLLMENT) — y compris un brouillon '
        'LEGACY créé avant l\'alignement RE↔NEW : draftStatus est DÉRIVÉ du '
        'type, jamais lu depuis un status persisté qui pourrait être une '
        'valeur périmée (auto-guérison au prochain re-save)', () {
      const reResumeIntent = EnrollmentDetailIntent.localDraftResume(
        enrollmentId: 'draft-re',
        studentId: 'stu-1',
        enrollmentType: 'RE_ENROLLMENT',
      );
      final policy = EnrollmentDetailPolicyResolver.fromIntent(reResumeIntent);
      expect(policy.draftEnrollmentType, 'RE_ENROLLMENT');
      expect(policy.draftStatus, 'IN_PROGRESS');
    });

    test(
      'reprise d\'un brouillon PRE : préserve PRE_ENROLLMENT/PRE_REGISTERED',
      () {
        const preResumeIntent = EnrollmentDetailIntent.localDraftResume(
          enrollmentId: 'draft-pre',
          enrollmentType: 'PRE_ENROLLMENT',
        );
        final policy = EnrollmentDetailPolicyResolver.fromIntent(
          preResumeIntent,
        );
        expect(policy.draftEnrollmentType, 'PRE_ENROLLMENT');
        expect(policy.draftStatus, 'PRE_REGISTERED');
      },
    );
  });
}
