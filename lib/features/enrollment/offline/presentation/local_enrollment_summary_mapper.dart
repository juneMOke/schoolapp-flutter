import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';

/// Un dossier LOCAL relève de la **superposition read-your-writes** (affiché en
/// tête de la liste serveur, et consultable en lecture seule au détail) ssi il
/// est **écrit localement mais pas encore synchronisé** : `PENDING_SYNC`
/// (finalisé, en file d'attente) ou `SYNC_ERROR` (push en échec, à rejouer).
/// Un `DRAFT` n'est pas encore finalisé (jamais listé) ; un `SYNCED` est
/// autoritatif côté serveur → il suit le chemin normal (consultation/reprise).
///
/// Source de vérité **unique** : partagée par le filtre de superposition du
/// listing (EnrollmentBloc) et la bascule lecture seule du détail
/// (EnrollmentDetailPage), pour qu'ils ne puissent jamais diverger.
bool isUnsyncedLocalWrite(SyncState syncState) =>
    syncState == SyncState.pendingSync || syncState == SyncState.syncError;

/// Projette un dossier LOCAL (read-your-writes) sur le [EnrollmentSummary]
/// consommé par le listing online — sert la **superposition optimiste** : les
/// dossiers créés sur la tablette et pas encore synchronisés sont affichés en
/// tête de la liste serveur (autoritaire). `enrollmentCode` = matricule local
/// s'il existe, sinon vide (« en cours d'attribution », rempli à l'ACK).
EnrollmentSummary localItemToEnrollmentSummary(LocalEnrollmentListItem item) =>
    EnrollmentSummary(
      enrollmentId: item.enrollmentId,
      enrollmentCode: item.matriculationNumber ?? '',
      status: item.status.apiValue,
      // Type conservé (axe distinct du statut) : un dossier RE_ENROLLMENT est
      // affiché « Réinscription » même s'il porte le statut PRE_REGISTERED.
      enrollmentType: item.enrollmentType.apiValue,
      // Axe synchro conservé : distingue un brouillon local (DRAFT, repris au
      // tap + badge « Brouillon ») des dossiers finalisés/synchronisés.
      syncState: item.syncState,
      student: StudentSummary(
        id: item.studentId,
        firstName: item.firstName,
        lastName: item.lastName,
        surname: item.surname ?? '',
        dateOfBirth: item.dateOfBirth,
        gender: item.gender == OfflineGender.female
            ? Gender.female
            : Gender.male,
      ),
    );

/// Projette un **candidat de réinscription** (vivier N-1, cohorte locale) sur le
/// [EnrollmentSummary] du listing. `enrollmentId` vide = pas encore de dossier
/// (tap → seed d'un brouillon RE) ; `syncState` null (n'est pas une écriture
/// locale) ; `enrollmentCode` = matricule N-1 ; statut « PENDING » (à
/// réinscrire) — un candidat n'a pas encore de statut d'inscription.
EnrollmentSummary reenrollmentCandidateToEnrollmentSummary(
  ReenrollmentCandidate c,
) => EnrollmentSummary(
  enrollmentId: '',
  enrollmentCode: c.matriculationNumber,
  status: 'PENDING',
  student: StudentSummary(
    id: c.studentId,
    firstName: c.firstName,
    lastName: c.lastName,
    surname: c.surname ?? '',
    dateOfBirth: c.dateOfBirth,
    gender: c.gender.toUpperCase() == 'FEMALE' ? Gender.female : Gender.male,
  ),
);
