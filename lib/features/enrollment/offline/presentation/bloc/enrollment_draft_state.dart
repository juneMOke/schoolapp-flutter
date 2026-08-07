import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';

// États du **brouillon par étape** du wizard — membres de la famille unique
// [EnrollmentOfflineState] (bloc Inscription offline fusionné), gardés dans
// leur fichier pour la lisibilité (1 famille, 2 fichiers thématiques).
// `EnrollmentDraftInitial` a disparu avec la fusion : l'état de repos est
// [EnrollmentOfflineInitial].

/// Brouillon démarré : ids client figés (aucune ligne écrite tant que l'étape 0
/// n'a pas été enregistrée).
class EnrollmentDraftStarted extends EnrollmentOfflineState {
  final String enrollmentId;
  final String studentId;

  const EnrollmentDraftStarted(this.enrollmentId, this.studentId);

  @override
  List<Object?> get props => [enrollmentId, studentId];
}

/// Écriture d'une étape en cours.
class EnrollmentDraftSaving extends EnrollmentOfflineState {
  const EnrollmentDraftSaving();
}

/// Étape enregistrée localement (avance le wizard).
class EnrollmentDraftStepSaved extends EnrollmentOfflineState {
  const EnrollmentDraftStepSaved();
}

/// Détail du brouillon chargé.
class EnrollmentDraftDetailLoaded extends EnrollmentOfflineState {
  final LocalEnrollmentDetail detail;

  const EnrollmentDraftDetailLoaded(this.detail);

  @override
  List<Object?> get props => [detail];
}

/// Brouillon confirmé localement : dossier en attente de synchro.
class EnrollmentDraftFinalizedPendingSync extends EnrollmentOfflineState {
  final String enrollmentId;

  const EnrollmentDraftFinalizedPendingSync(this.enrollmentId);

  @override
  List<Object?> get props => [enrollmentId];
}

class EnrollmentDraftError extends EnrollmentOfflineState {
  final String message;

  const EnrollmentDraftError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Doublon de téléphone détecté à l'enregistrement de l'étape Tuteurs —
/// distinct de [EnrollmentDraftError] pour que seul `GuardianInfoStep` y
/// réagisse (pas le toast générique du stepper), même patron que
/// [EnrollmentDraftFinalizeError].
class EnrollmentDraftGuardianPhoneConflict extends EnrollmentOfflineState {
  final String phoneNumber;
  final String message;

  const EnrollmentDraftGuardianPhoneConflict(this.phoneNumber, this.message);

  @override
  List<Object?> get props => [phoneNumber, message];
}

/// Échec de la **finalisation** spécifiquement — distinct de
/// [EnrollmentDraftError] (étape/seed) pour que la sur-couche de résultat de
/// la validation finale (`EnrollmentFinalizeOverlay`) soit seule à réagir,
/// sans déclencher aussi le toast générique du scope du stepper.
class EnrollmentDraftFinalizeError extends EnrollmentOfflineState {
  final String message;

  const EnrollmentDraftFinalizeError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Sonde au tap RE/PRE : un dossier local existe DÉJÀ pour ce candidat → la
/// page l'ouvre au lieu de seeder un doublon. [syncState] pilote le mode
/// (option b) : `DRAFT` → reprise éditable ; finalisé → lecture seule.
class EnrollmentLocalDossierExisting extends EnrollmentOfflineState {
  final String enrollmentId;
  final SyncState syncState;

  const EnrollmentLocalDossierExisting(this.enrollmentId, this.syncState);

  @override
  List<Object?> get props => [enrollmentId, syncState];
}
