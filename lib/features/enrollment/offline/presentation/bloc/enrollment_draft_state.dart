import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';

abstract class EnrollmentDraftState extends Equatable {
  const EnrollmentDraftState();

  @override
  List<Object?> get props => [];
}

class EnrollmentDraftInitial extends EnrollmentDraftState {
  const EnrollmentDraftInitial();
}

/// Brouillon démarré : ids client figés (aucune ligne écrite tant que l'étape 0
/// n'a pas été enregistrée).
class EnrollmentDraftStarted extends EnrollmentDraftState {
  final String enrollmentId;
  final String studentId;

  const EnrollmentDraftStarted(this.enrollmentId, this.studentId);

  @override
  List<Object?> get props => [enrollmentId, studentId];
}

/// Écriture d'une étape en cours.
class EnrollmentDraftSaving extends EnrollmentDraftState {
  const EnrollmentDraftSaving();
}

/// Étape enregistrée localement (avance le wizard).
class EnrollmentDraftStepSaved extends EnrollmentDraftState {
  const EnrollmentDraftStepSaved();
}

/// Détail du brouillon chargé.
class EnrollmentDraftDetailLoaded extends EnrollmentDraftState {
  final LocalEnrollmentDetail detail;

  const EnrollmentDraftDetailLoaded(this.detail);

  @override
  List<Object?> get props => [detail];
}

/// Brouillon confirmé localement : dossier en attente de synchro.
class EnrollmentDraftFinalizedPendingSync extends EnrollmentDraftState {
  final String enrollmentId;

  const EnrollmentDraftFinalizedPendingSync(this.enrollmentId);

  @override
  List<Object?> get props => [enrollmentId];
}

class EnrollmentDraftError extends EnrollmentDraftState {
  final String message;

  const EnrollmentDraftError(this.message);

  @override
  List<Object?> get props => [message];
}
