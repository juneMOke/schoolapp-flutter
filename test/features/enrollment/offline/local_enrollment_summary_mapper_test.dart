import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/local_enrollment_summary_mapper.dart';

void main() {
  LocalEnrollmentListItem item({
    String? matricule,
    OfflineGender gender = OfflineGender.female,
    String status = 'IN_PROGRESS',
    EnrollmentType enrollmentType = EnrollmentType.newEnrollment,
    SyncState syncState = SyncState.pendingSync,
  }) => LocalEnrollmentListItem(
    enrollmentId: 'e1',
    studentId: 's1',
    firstName: 'Amina',
    lastName: 'Moke',
    surname: 'Junior',
    dateOfBirth: '2015-04-02',
    gender: gender,
    enrollmentType: enrollmentType,
    status: OfflineEnrollmentStatus.fromApiValue(status),
    matriculationNumber: matricule,
    enrollmentDate: '2026-07-10',
    syncState: syncState,
  );

  test('projette ids, statut, identité et genre', () {
    final s = localItemToEnrollmentSummary(item());
    expect(s.enrollmentId, 'e1');
    expect(s.status, 'IN_PROGRESS');
    expect(s.student.id, 's1');
    expect(s.student.firstName, 'Amina');
    expect(s.student.surname, 'Junior');
    expect(s.student.gender, Gender.female);
  });

  test('enrollmentCode = matricule local si présent, sinon vide', () {
    expect(
      localItemToEnrollmentSummary(
        item(matricule: 'KIN-2025-0001'),
      ).enrollmentCode,
      'KIN-2025-0001',
    );
    expect(localItemToEnrollmentSummary(item()).enrollmentCode, '');
  });

  test('propage syncState → isLocalDraft distingue un brouillon local', () {
    // L'axe synchro survit à la projection : la ligne DRAFT est repérable
    // (badge « Brouillon » + reprise au tap), les autres non.
    final draft = localItemToEnrollmentSummary(
      item(syncState: SyncState.draft),
    );
    expect(draft.syncState, SyncState.draft);
    expect(draft.isLocalDraft, isTrue);

    final pending = localItemToEnrollmentSummary(
      item(syncState: SyncState.pendingSync),
    );
    expect(pending.syncState, SyncState.pendingSync);
    expect(pending.isLocalDraft, isFalse);
  });

  test('propage enrollmentType → isReEnrollment distingue une réinscription '
      'même au statut PRE_REGISTERED', () {
    // Cœur du bug : un dossier RE porte le statut PRE_REGISTERED (comme une
    // pré-inscription) mais reste une réinscription → l'affichage doit s'appuyer
    // sur le type, pas sur le statut.
    final re = localItemToEnrollmentSummary(
      item(
        enrollmentType: EnrollmentType.reEnrollment,
        status: 'PRE_REGISTERED',
      ),
    );
    expect(re.enrollmentType, 'RE_ENROLLMENT');
    expect(re.isReEnrollment, isTrue);
    expect(re.status, 'PRE_REGISTERED');

    final pre = localItemToEnrollmentSummary(
      item(
        enrollmentType: EnrollmentType.preEnrollment,
        status: 'PRE_REGISTERED',
      ),
    );
    expect(pre.enrollmentType, 'PRE_ENROLLMENT');
    expect(pre.isReEnrollment, isFalse);
  });

  test('genre non-féminin → male (Gender à 2 valeurs)', () {
    expect(
      localItemToEnrollmentSummary(
        item(gender: OfflineGender.male),
      ).student.gender,
      Gender.male,
    );
    expect(
      localItemToEnrollmentSummary(
        item(gender: OfflineGender.other),
      ).student.gender,
      Gender.male,
    );
  });

  group('isUnsyncedLocalWrite (source de vérité read-your-writes)', () {
    test('PENDING_SYNC et SYNC_ERROR → true (surface read-your-writes)', () {
      expect(isUnsyncedLocalWrite(SyncState.pendingSync), isTrue);
      expect(isUnsyncedLocalWrite(SyncState.syncError), isTrue);
    });

    test('SYNCED → false (autoritatif serveur : chemin normal/reprise)', () {
      // Garde-fou : un dossier créé hors-ligne PUIS synchronisé garde son
      // statut métier (ex. IN_PROGRESS) — il ne doit PAS être figé en lecture
      // seule, sinon la reprise serait bloquée. Il suit le chemin serveur.
      expect(isUnsyncedLocalWrite(SyncState.synced), isFalse);
    });

    test('DRAFT → false (brouillon repris via le wizard, PAS lecture seule)', () {
      // Le brouillon est désormais LISTÉ, mais son tap REPREND le wizard
      // (chemin séparé) au lieu d'ouvrir la consultation lecture seule — ce
      // prédicat, qui gouverne la bascule read-only, reste donc faux pour DRAFT.
      expect(isUnsyncedLocalWrite(SyncState.draft), isFalse);
    });
  });
}
